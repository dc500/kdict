# encoding: utf-8
require 'rubygems'  # not necessary for Ruby 1.9
require 'mongo'
require 'hpricot' # for parsing weird stuff in Hanja column
require 'pp'

module KDict
    class Migration

        def initialize
            db = Mongo::Connection.new("localhost", 27017).db("kdict")

            @korean_english = db.collection("korean_english")
            @m_korean       = db.collection("m_korean")
            @p_korean       = db.collection("p_korean")
            @gsso_korean    = db.collection("gsso_korean")

            # inserting into
            @entries = db.collection("entries")
            @entries.drop()
            
            # These IDs are just evil, they cause problems, we drop them
            @evil_ids = [
                233358
            ]
        end

        
        def import_all
            import(@m_korean)
            import(@p_korean)
            import(@gsso_korean)
            import(@korean_english)
        end


        def import(collection)
            cursor = collection.find
            total = cursor.count
            puts "#{total} entries in #{ collection.name } to process"

            count = 0
            # Start with largest DB
            cursor.each do |row|
                count += 1
                if count % 1000 == 0
                    puts "#{count} of #{total}"
                end

                output = Hash.new()
                flags = Array.new()

                if @evil_ids.include?(row['wordid'])
                    next
                end

                if (row['def'] == "see 6000") || (row['def'] == "see gsso")
                    resource = nil
                    # skip the current record
                    if (row['def'] == "see 6000")
                        resource = @m_korean
                    else (row['def'] == "see gsso")
                        resource = @gsso_korean
                    end

                    # Some words have whitespace on the end...
                    sub_cursor = resource.find( 'word' => /^\s*#{ row['word'] }\s*$/)
                        if sub_cursor.count > 1
                            puts "\n\n"
                            puts "Found multiple possibilities"
                            puts "#{ row['word'] } (#{ row['wordid'] })"
                            sub_cursor.each do |meh|
                                puts "#{meh['word']} - #{meh['def']} (#{ meh['wordid'] })"
                            end
                            #other = sub_cursor.next_document
                            #puts sub_cursor.count
                            puts "\n\n"
                        elsif sub_cursor.count == 0
                            flags.push("Could not find linked article in '#{ row['def'] }'")
                        end


                    #other = sub_cursor.next_document
                    #row['def']   = other['def']
                    #row['hanja'] = other['hanja']
                    #row['pos']   = other['pos']
                    # PosN is useless in m_korean
                    next
                end

                if (row['def'] =~ /^see /i)
                    flags.push("See... definition")
                    # Ideally we want to be able to link these
                end


                # if any required fields are empty, flip out
                'def word'.split.each do |key|
                    if (row[key].nil? or row[key] == "")
                        flags.push("required field #{ key } is empty")
                    end
                end

                if output['korean'] =~ /다\s*$/
                    if (output['pos'] != 'verb' ||
                        output['pos'] != 'adjective')
                    puts output.inspect
                    flags.push("Word with 다 ending appears to not be a verb/adj")
                    end
                end

                # m_korean always has uppercase first letters. It's annoying
                if (collection.name == "m_korean" && row['def'].class == String)
                    # longest method ever.
                    row['def'] = row['def'][0,1].downcase + row['def'][1,row['def'].length]
                end

                eng, en_flags = KDict::Migration.clean_english(row['def'])
                if flags.size > 0
                    flags.push(en_flags)
                end
                output['definitions'] = Hash.new
                output['definitions']['english'] = Array.new
                output['definitions']['english'].push(eng)

                output['korean'] = Hash.new
                output['korean']['word'], flag  = KDict::Migration.clean_korean(row['word'])
                if flag
                    flags.push(flag)
                end
                
                # Saving the output for search usage
                output['korean']['length'] = output['korean']['word'].length


                if (collection.name != "p_korean")
                    output['hanja'], flag  = KDict::Migration.clean_hanja(row['hanja'])
                    if flag
                        flags.push(flag)
                    end
                end

                output['pos'], flag = KDict::Migration.clean_pos(row['pos'])
                if flag
                    flags.push(flag)
                end

                row.each do |key, val|
                    if (row['key'] == '\N')
                        row['key'] = nil
                    end
                end

                #if (flags.size > 0)
                #    puts row.inspect
                #end


                output['submitter'] = 'Ruby migration tool'
                output['flags'] = flags

                output['old'] = Hash.new
                output['old']['wordid']    = row['wordid']
                output['old']['submitter'] = row['submitter']
                output['old']['table']     = collection.name

                output['created_at'] = Time.now;
                output['updated_at'] = Time.now;


                # Write the data
                @entries.insert( output )
            end
        end

        def self.integers_to_korean(input)
            done = input.gsub(/(\\{1,2}\d{3})+/) do |match|
                match.scan(/\d+/).map { |n| n.to_i(8) }.pack("C*").force_encoding('utf-8')
            end
            return done
        end
        
        def self.clean_korean(raw)
            flag = false
            if (raw.class == Fixnum)
                clean = raw.to_s
            else
                clean = String.new(raw)
            end

            # God knows what we have in here
            if (clean =~ /[a-z]/i)
                flag = 'Korean data contains alphabet characters'
            end

            return clean, flag
        end

        # Insert into new collection
        def self.clean_english(raw)
            flags = []
            # raw can be a number like "18"
            if (raw.class == Fixnum)
                clean = raw.to_s
            else
                clean = String.new(raw)
            end

            if (clean =~ /^\d$/)
                #puts "Def is just a number"
            end

            # First get rid of <b> and <i> tags. They're useful for meaning/context
            clean.gsub!(/<\/?[bi]>/, '"')
            
            # Get rid of all HTML
            clean = kill_html(clean)

            # non-english content in english def
            if !clean.ascii_only?
                flags.push 'Non-ascii content in English def'
            end
            
            # I don't think we should have plurals
            # At a later date we can stem stuff
            clean.gsub!('(s)', '')

            # remove any double-spaces, ick
            clean.gsub!(/ +/, ' ')

            # There's a lot of content with leading parens and no closing parens
            if clean =~ /^\s*\(/
                if clean !~ /\)/
                    clean.gsub!(/^\s*\(\s*/, '')
                end
            end

            #

            # Change dumb acronyms
            clean.gsub!(/(([A-Z])\.)/, '\2')

            # Make sure parens have spaces around them and not after
            clean.gsub!(/\s*\(\s*/, ' (')
            clean.gsub!(/\s*\)\s*/, ') ')

            # Parens shouldn't have space before commas
            clean.gsub!(/\)\s*([,.!?])/, ')\1')

            # add space in after full stop
            clean.gsub!(/([,.!?;:])\S/, '\1 ')
            clean.gsub!(/\s+([,.!?;:])/, '\1')


            # This comes up quite a lot
            clean.gsub!(/(^|\s)sb/, ' somebody')
            clean.gsub!('sth', 'something')

            # Leading spaces before a 's
            clean.gsub!(/\s+'s\s/, "'s ")

            clean.gsub!(/\si\s/, ' I ')

            # If we have weird parens
            if (clean =~ /[\[\]\{\}]/)
                flags.push "English contains square brackets or braces"
            end

            # goddamn backslashes
            if (clean =~ /\\/)
                flags.push 'English contains backslashes'

                # First change \\011 which is a full-with space
                clean.gsub!('\\\\011', ' ')

                # This usually means that the text is badly formatted korean as in
                # Scrabble \\354\\203\\201\\355\\221\\234\\353\\252\\205
                # Which should be "Scrabble\354\203\201\355\221\234\353\252\205"
                #  aka 상표명

                # Some other times the text just has junk backslashes
                # e.g. a counter, meaning \\"th\\"

                # Replace all Korean-looking things with their real stuff
                clean = integers_to_korean(clean)

                # Some literally have a \r or \t
                clean.gsub!(/\\r/, '')
                clean.gsub!(/\\t/, '')

                # Remove any remaining double backslash junk
                clean.gsub!(/\\\\/, '')

                # Then change into their real UTF-8 characters
                clean = clean.split(//u).join
            end

            # Awful backtick character
            if (clean =~ /`/)
                #if (clean =~ /`s/)
                #    flags.push("Replaced ` with ' but wasn't in front of s")
                #end
                clean.gsub!(/`/, "'")
            end


            # leading/trailing spaces
            clean.gsub!(/^\s+/, '')
            clean.gsub!(/\s+$/, '')

            # Acronym probably
            if (clean =~ /^[A-Z0-9 ,']+$/)
                flags.push 'English contains acronym?'
            end

            # Want to make two instances of the word
            if (clean =~ /\(u\)/)
                british  = String.new(clean)
                american = String.new(clean)

                american.gsub!(/\(u\)/, '')
                british.gsub!(/\(u\)/, 'u')
                # TODO return both
                #clean = [ american, british ]
            end

            #if (raw != clean)
            #    puts "CHANGED"
            #    puts raw
            #    puts clean
            #    puts "---------"
            #end

            return clean, flags
        end

        def self.clean_pos(in_tag)
            flag = false
            tag  = nil

            case in_tag
            when ""
            when 0
            when 1, "명"
                tag = 'noun'
            when 2, "동"
                tag = 'verb'
            when 3, "부"
                tag = 'adverb'
            when 4
                tag = 'adjective'
            when 5
                tag = 'counter'
            when 6
                # ???
            when 7, "지"
                tag = 'location'
            when 9, "수"
                tag = 'number'
            when 10
                flag = true
            when "대" # pronoun
                tag = 'pronoun'
            when "감"
                tag = 'exclamation'
            when "관"
                tag = 'interjection'
            when "접"
                tag = 'preposition'
            when "의" # posession?
                tag = 'possession'
                flag = 'possessive POS unsure'
            when "도" 
            when "보" # helping verb
            when "불" # ??
                flag = 'unknown POS tag'
            when "형" # adj
            when "curious" 
                delete = true
            end

            if tag.nil?
                flag = "POS tag '#{ tag }' unrecognised or not found"
            end

            return tag, flag # rhymes, hee hee
        end

        def self.clean_hanja(raw)
            clean = String.new(raw)
            flag = false

            # Destroy evil HTML
            #clean.gsub!(/<.*?>/, '')

            clean = kill_html(clean)

            if (clean =~ /[a-z0-9 -,]/i)
                flag = "Hanja contains alphanumeric"
            end

            return clean, flag
        end

        # Hanja can be a clever mix of HTML with JS and HTML elements within the JS
        # We need the power of an HTML parser
        def self.kill_html(raw)
            raw.gsub!('"oak"', 'oak') # wordid: 222875 has invalid HTML. Awful hack
            return Hpricot(raw).inner_text
        end
    end
end



if ARGV[0] == 'go'
    puts "GOING"

    migrate = KDict::Migration.new()
    migrate.import_all()
end


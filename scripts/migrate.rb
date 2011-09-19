# encoding: utf-8
require 'rubygems'  # not necessary for Ruby 1.9
require 'mongo'
require 'hpricot' # for parsing weird stuff in Hanja column
require 'pp'

##### WARNING
#             This skips All the validation in the DB as it inserts directly
#             and ignores all the magical Mongoose validation.

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
            @entries.create_index([
                ['korean.hangul', Mongo::ASCENDING],
            ])

            @updates = db.collection("updates")
            @updates.drop()
            @entries.create_index([
                ['entry', Mongo::ASCENDING],
            ])

            @users = db.collection("users")
            @users.drop()
            @user_id = @users.insert( {
              "display_name" => 'Migration script',
              "username"     => 'migrate',
              "email"        => 'migrate',
            })


            #@updates.create_index

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
                tags = Array.new()

                if @evil_ids.include?(row['wordid'])
                    next
                end

                # Now that we're inserting multiple stuff, this shouldn't be a problem
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
                            puts "Found multiple possibilities via def '#{ row['def'] }'"
                            puts "Original: #{ row['word'] } (#{ row['wordid'] })"
                            puts "Results found:"
                            sub_cursor.each do |meh|
                                puts "\t#{meh['word']} - #{meh['def']} (#{ meh['wordid'] })"
                                puts "\tFull: " + meh.inspect
                            end
                            #other = sub_cursor.next_document
                            #puts sub_cursor.count
                            puts "\n\n"
                        elsif sub_cursor.count == 0
                            tags.push("Could not find linked article in '#{ row['def'] }'")
                        end


                    #other = sub_cursor.next_document
                    #row['def']   = other['def']
                    #row['hanja'] = other['hanja']
                    #row['pos']   = other['pos']
                    # PosN is useless in m_korean
                    next
                end

                if (row['def'] =~ /^see /i)
                    tags.push("English def is see")
                    # Ideally we want to be able to link these
                end


                # if any required fields are empty, flip out
                { 'def' => 'english',
                  'word' => 'hangul'}.each_pair do |old, new|
                    if (row[old].nil? or row[old] == "")
                        tags.push("required field #{ new } empty")
                    end
                end

                # m_korean always has uppercase first letters. It's annoying
                if (collection.name == "m_korean" && row['def'].class == String)
                    # longest method ever.
                    row['def'] = row['def'][0,1].downcase + row['def'][1,row['def'].length]
                end

                eng, en_tags = KDict::Migration.clean_english(row['def'])
                if en_tags.size > 0
                    tags.push(en_tags)
                end
                output['definitions'] = Hash.new
                output['definitions']['english'] = Array.new
                output['definitions']['english'].push(eng)

                kor = Hash.new
                kor['hangul'], tag  = KDict::Migration.clean_korean(row['word'])
                if tag
                    tags.push(tag)
                end
                
                # Saving the output for search usage
                # This is now done by a mapreduce op
                kor['length'] = kor['hangul'].length


                if (collection.name != "p_korean")
                    hanja, tag  = KDict::Migration.clean_hanja(row['hanja'])
                    output['hanja'] = [ hanja ]
                    if tag
                        tags.push(tag)
                    end
                end

                output['pos'], tag = KDict::Migration.clean_pos(row['pos'])
                if tag
                    tags.push(tag)
                end
                if kor['hangul'] =~ /다\s*$/
                    if (output['pos'] !~ /^verb|adjective$/)
                        #puts "Output: " + kor['hangul'] + ' ' + output['pos']
                        tags.push("Word with 다 ending appears to not be a verb/adj")
                    end
                end

                # Get rid of empty things
                row.each do |key, val|
                    if (row['key'] == '\N')
                        row['key'] = nil
                    end
                end

                #if (tags.size > 0)
                #    puts row.inspect
                #end


                #output['submitter'] = 'Ruby migration tool'
                # TODO Do we want to change the way tags are being handled?
                #      Instead they could be set by running the Mongoose validation
                #      on each record, via Javascript
                output['tags'] = tags

                output['legacy'] = Hash.new
                output['legacy']['wordid']    = row['wordid']
                output['legacy']['submitter'] = row['submitter']
                output['legacy']['table']     = collection.name

                #output['created_at'] = Time.now;
                #output['updated_at'] = Time.now;

                # Write the data
                # THIS IS WAY TOO SLOW
                count = @entries.find( 'korean.hangul' => kor['hangul'] ).count
                if count > 0
                    #puts "Updating existing #{kor['hangul']}"
                    entry_id = @entries.update(
                        { 'korean.hangul' => kor['hangul'] }, 
                        {
                            "$push" => { "meanings" => output }
                        },
                        { :upsert => true }
                    )
                else
                    #puts "New entry: #{kor['hangul']}"
                    entry_id = @entries.insert( 
                        {
                            'korean' => kor,
                            'meanings' => [ output ],
                        }
                    )
                end

                # UPSERT SEEMS BROKEN

                # We now do an upsert, not a plain insert
                #entry_id = @entries.save(
                #    { 'korean.hangul' => kor['hangul'] }, 
                #    {
                #        'korean' => kor,
                #        "$push" => { "meanings" => output }
                #    },
                #    { :upsert => true }
                #)



                # TODO: "Update" entries
                update = Hash.new
                update['entry']  = entry_id
                update['after']  = output
                update['type']   = 'new'
                update['status'] = Hash.new
                update['user']      = @user_id
                update['revision_num'] = 1
                update_id = @updates.insert( update )
                
                @entries.update(
                    { '_id' => entry_id },
                    { "$push" => { 'update_ids' => update_id } },
                    { :upsert => true }
                )



            end
        end

        def self.integers_to_korean(input)
            done = input.gsub(/(\\{1,2}\d{3})+/) do |match|
                match.scan(/\d+/).map { |n| n.to_i(8) }.pack("C*").force_encoding('utf-8')
            end
            return done
        end
        
        def self.clean_korean(raw)
            tag = false
            if (raw.class == Fixnum)
                clean = raw.to_s
            else
                clean = String.new(raw)
            end

            # God knows what we have in here
            if (clean =~ /[a-z]/i)
                tag = 'Korean data contains alphabet characters'
            end

            # Some have \t or \r literals
            clean.gsub!(/\\(t|r)/, '')


            
            # leading/trailing spaces
            clean.gsub!(/^\s+/, '')
            clean.gsub!(/\s+$/, '')

            return clean, tag
        end

        # Insert into new collection
        def self.clean_english(raw)
            tags = []
            # raw can be a number like "18"
            if (raw.class == Fixnum)
                clean = raw.to_s
            else
                clean = String.new(raw)
            end

            if (clean =~ /^\d$/)
                #puts "Def is just a number"
            end

            # Replace <b> and <i> tags with ", useful for context/emphasis later
            clean.gsub!(/<\/?[bi]>/, '"')
            
            # Get rid of all remaining HTML
            clean = kill_html(clean)

            # non-english content in english def
            if !clean.ascii_only?
                tags.push 'Non-ascii in English def'
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
                tags.push "English contains square brackets or braces"
            end

            # goddamn backslashes
            if (clean =~ /\\/)
                tags.push 'English contains backslashes'

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
                #    tags.push("Replaced ` with ' but wasn't in front of s")
                #end
                clean.gsub!(/`/, "'")
            end


            # leading/trailing spaces
            clean.gsub!(/^\s+/, '')
            clean.gsub!(/\s+$/, '')

            # Acronym probably
            if (clean =~ /^[A-Z0-9 ,']+$/)
                tags.push 'English contains acronym?'
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

            return clean, tags
        end

        def self.clean_pos(in_pos)
            tag = false
            pos  = nil

            case in_pos
            when ""
            when 0
            when 1, "명"
                pos = 'noun'
            when 2, "동"
                pos = 'verb'
            when 3, "부"
                pos = 'adverb'
            when 4
                pos = 'adjective'
            when 5
                pos = 'counter'
            when 6
                # ???
            when 7, "지"
                pos = 'location'
            when 9, "수"
                pos = 'number'
            when 10
                tag = true
            when "대" # pronoun
                pos = 'pronoun'
            when "감"
                pos = 'exclamation'
            when "관"
                pos = 'interjection'
            when "접"
                pos = 'preposition'
            when "의" # posession?
                pos = 'possession'
                tag = 'possessive POS unsure'
            when "도" 
            when "보" # helping verb
            when "불" # ??
                tag = 'unknown POS tag'
            when "형" # adj
            when "curious" 
                delete = true
            end

            if pos.nil?
                tag = "unknown POS tag '#{ in_pos }'"
            end

            return pos, tag
        end

        def self.clean_hanja(raw)
            clean = String.new(raw)
            tag = false

            # Destroy evil HTML
            #clean.gsub!(/<.*?>/, '')

            clean = kill_html(clean)

            if (clean =~ /[a-z0-9 -,]/i)
                tag = "Hanja contains alphanumeric"
            end

            return clean, tag
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


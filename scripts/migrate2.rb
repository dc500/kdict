# encoding: utf-8
require 'rubygems'  # not necessary for Ruby 1.9
require 'mongo'
require 'hpricot' # for parsing weird stuff in Hanja column
require 'pp'

require 'net/http'
require 'uri'
require 'json'


# 137240
# 136696
# ------
# 000544

# 137240 Same # entries but there's no guarantee it has all the meanings

##### WARNING
#             This skips All the validation in the DB as it inserts directly
#             and ignores all the magical Mongoose validation.

def _puts(msg)
    if false
        puts msg
    end
end


module KDict
    class Migration

        @@hanja_range = [
            [ 0x4E00,  0x9FFF, 'hanja' ], # CJK Unified Ideographs
            [ 0xF900, 0x2FA1F, 'hanja' ]  # Massive mess of CJK and other stuff
        ]

        @@hangul_range = [
            [ 0x1100, 0x11FF, 'hangul' ], # Hangul Jamo	
            [ 0x3130, 0x318F, 'hangul' ], # Hangul Compatibility Jamo	
            [ 0xA960, 0xA97F, 'hangul' ], # Hangul Jamo Extended-A	
            [ 0xAC00, 0xD7AF, 'hangul' ], # Hangul Syllables	
            [ 0xD7B0, 0xD7FF, 'hangul' ], # Hangul Jamo Extended-B	
        ]

        def initialize
            db = Mongo::Connection.new("localhost", 27017).db("kdict")

            @korean_english = db.collection("korean_english")
            @m_korean       = db.collection("m_korean")
            @p_korean       = db.collection("p_korean")
            @gsso_korean    = db.collection("gsso_korean")

            # For speed issues
            @korean_english.ensure_index([
                ['word', Mongo::ASCENDING],
            ])
            @korean_english.ensure_index([
                ['def', Mongo::ASCENDING],
            ])
            @korean_english.create_index([
                ['word', Mongo::ASCENDING],
                ['def',  Mongo::ASCENDING],
            ])
            @m_korean.ensure_index([
                ['word', Mongo::ASCENDING],
            ])
            @p_korean.ensure_index([
                ['word', Mongo::ASCENDING],
            ])
            @gsso_korean.ensure_index([
                ['word', Mongo::ASCENDING],
            ])

            # inserting into
            @entries = db.collection("entries")
            @entries.drop()
            @entries.ensure_index([
                ['korean.hangul', Mongo::ASCENDING],
            ])

            @updates = db.collection("updates")
            @updates.drop()
            @entries.ensure_index([
                ['entry', Mongo::ASCENDING],
            ])

            @users = db.collection("users")
            @users.drop()
            @user_id = @users.insert( {
                "display_name" => 'Migration script',
                "username"     => 'migrate',
                "email"        => 'migrate',
            })

            # Set up all initial tags
            @tags = db.collection("tags")
            @tags.drop()
            data = {
                'english_see' => {
                    "type"  => 'problem',
                    "short" => '!see',
                    "long"  => 'English definition contains "see..." reference'
                },
                'hangul_undef' => {
                    "type"  => 'problem',
                    "short" => '!nohangul',
                    "long"  => 'Hangul is undefined.'
                },
                'english_undef' => {
                    "type"  => 'problem',
                    "short" => '!noenglish',
                    "long"  => 'English is undefined.'
                },
                'korean_content' => {
                    "type"  => 'problem',
                    "short" => '!hangul',
                    "long"  => 'Hangul field contains non-hangul characters'
                },
                'non_hanja' => {
                    "type"  => 'problem',
                    "short" => '!hanja',
                    "long"  => 'Hanja field contains non-hanja characters'
                },
                'check_merge' => {
                    "type"  => 'problem',
                    "short" => '!merge',
                    "long"  => 'Check that meanings have been merged correctly. Identify any duplicate meanings and remove/merge them.'
                },
                'non-ascii' => {
                    'type'  => 'problem',
                    'short' => '!english',
                    'long'  => 'English definition contains non-ascii characters.'
                },
                'english-parens' => {
                    'type'  => 'problem',
                    'short' => '!parens',
                    'long'  => "English contains parenthesis, square brackets or braces. Check usage and clean up."
                },
                'da_not_verb' => {
                    'type'  => 'problem',
                    'short' => '!daend',
                    'long'  => "Word with 다 ending appears to not be a verb/adj. Check POS tag."
                },
                'english_acronym' => {
                    'type'  => 'problem',
                    'short' => '!acronym',
                    'long'  => 'English definition appears to contain acronym. Confirm andexpand'
                },
                'english_backslashes' => {
                    'type'  => 'problem',
                    'short' => '!slashes',
                    'long'  => 'English contains backslashes, please clean up'
                },
                'unknown_pos' => {
                    'type'  => 'problem',
                    'short' => '!pos',
                    'long'  => 'POS tag is unknown. Please check legacy POS information or choose from knowledge'
                },
                'link_error' => {
                    'type'  => 'problem',
                    'short' => '!link',
                    'long'  => "Old definition was 'see...' but could not find linked article"
                }
            }
            @tag_refs = Hash.new
            data.each_pair do |key, doc|
                id = @tags.insert(doc)
                @tag_refs[key] = id
            end
        end


        def import_all
            import(@korean_english)
            
            # Add missing stuff
            import(@m_korean)
            import(@p_korean)
            import(@gsso_korean)
        end
        

        def import(collection)
            cursor = collection.find #( { 'word' => '치다' } )
            total = cursor.count
            puts "#{total} entries in #{ collection.name } to process"

            count = 0
            # Start with largest DB
            cursor.each do |row|
                count += 1
                #if (count < 80000)
                #    next
                #end
                #if (count > 100000)
                #  break
                #end

                if ((count % 1000) == 0)
                    puts "#{count} of #{total}"
                end

                kor, senses, tags = parse_clean_entry(collection, row)

                # Sometimes we want to skip
                if (kor.nil? && senses.nil? && tags.nil?)
                  puts "Skipping as null content:"
                  next
                end


                # find existing entries of the same name
                existing_cursor = @entries.find( 'korean.hangul' => kor['hangul'] )
                is_update = false
                if existing_cursor.count > 1
                    puts "We should never have more than 1 entry with the same hangul #{kor['hangul']}. Found #{existing_cursor.count}. Something has gone wrong."
                    exit
                    

                # So there's an existing entry
                # If there is, we'll merge the new senses with those existing
                elsif existing_cursor.count == 1

                    existing_cursor = existing_cursor.first
                    if @entries.find(
                      { 'korean.hangul' => kor['hangul'],
                        'senses.legacy.wordid' => row['wordid'],
                        'senses.legacy.table' => collection.name }
                    ).count == 1
                      puts "NO WAY ARE WE INSERTING THIS BABY #{kor['hangul']} with reference def #{row['def']} and id: #{row['wordid']}"
                      next
                    end
                    is_update = true

                    entry_id = existing_cursor['_id']

                    tags.push(@tag_refs['check_merge'])

                    if senses.length > 1
                      puts "Update: #{kor['hangul']},\t#{senses.length} senses"
                    end

                    updated_entry = @entries.update(
                        { 'korean.hangul' => kor['hangul'] }, 
                        { "$pushAll" => { "senses" => senses }, },
                        #'updated_at' => Time.now },
                        { :upsert => true }
                    )

                    tags.each do |tag|
                        @entries.update(
                            { 'korean.hangul' => kor['hangul'] }, 
                            { "$addToSet" => { "tags" => tag } },
                        )
                    end

                # New entry, insert it on its own
                else
                    #KDict::Migration.post_entry( { 
                    #    'korean' => kor,
                    #    'senses' => senses,
                    #    #'tags' => tags,
                    #} )

                    entry_id = @entries.insert( {
                        'korean' => kor,
                        'senses' => senses,
                        'tags' => tags,
                        'created_at' => Time.now,
                        'updated_at' => Time.now
                    } )
                end


                update = Hash.new
                update['entry']  = entry_id
                if is_update
                    update['type']   = 'update'
                    ## TODO before senses not done yet. lol.
                    ##update['before']  = senses
                else
                    update['type']   = 'new'
                end
                update['content']  = { 'korean' => kor, 'senses' => senses, 'tags' => tags }
                update['user']   = @user_id
                update_id = @updates.insert( update )


                # no longer updating list of updates
                #@entries.update(
                #    { 'korean.hangul' => kor['hangul'],
                #        'updated_at' => Time.now },
                #    #{ '_id' => entry_id },
                #    { "$push" => { 'updates' => update_id } },

                #    { :upsert => true }
                #)
            end
        end



        # Can return multiple entries
        def parse_clean_entry(collection, row)

            tags = Array.new()

            kor = Hash.new
            kor['hangul'], tag  = KDict::Migration.clean_hangul(row['word'])
            if tag
                tags.push(@tag_refs[tag])
            end
            kor['hangul_length'] = kor['hangul'].length

            #row['table'] = collection.name

            # Now that we're inserting multiple stuff, this shouldn't be a problem
            if (row['def'] == "see 6000") || (row['def'] == "see gsso")

                # All we have to go on to link entries is their Hangul
                # So it's extremely likely we'll get multiple senses from a
                # single "see ___" entry
                # With the new 'sense' data structure this isn't a problem, but
                # we still want to differentiate these at a later date so we
                # can tie the example sentences to the right sense, which will
                # be based on the word ID of the thing that referenced it
                #
                # Still with me?  Didn't think so.
                #
                # Oh also, we don't want to add the same sense multiple times
                # Which is extremely likely to happen, as we not only parse the
                # talbe that contains the refererences (korean_english), but also
                # the tables that it references, because it misses a couple of
                # thousand definitions.
                # Wonderful.

                see_coll = nil


                

                if (row['def'] == "see 6000")
                    if (collection.name == 'm_korean')
                        puts "Self-referential?"
                        puts row.inspect
                        return nil, nil, nil
                    end
                    see_coll = @m_korean
                    #row['table'] = 'm_korean'
                else (row['def'] == "see gsso")
                    see_coll = @gsso_korean
                    #row['table'] = 'gsso_korean'
                end

                # Some words have whitespace on the end...
                sub_cursor = see_coll.find( 'word' => /^#{ row['word'] }$/)
                senses = Array.new()

                # Want a list of all wordids in the original that contained "see___"
                all_see = collection.find( { 'word' => /^#{ row['word'] }$/,
                                             'def'  => /^see (6000|gsso)/i },
                                           { :fields => [ 'wordid', 'word' ] } )
                

                see_wordids = Array.new
                see_words = Array.new
                all_see.each do |moo|
                    see_wordids.push(moo['wordid'])
                    see_words.push(moo['word'])

                    if moo['word'] != row['word']
                      puts "WHOA WHOA WHOA, Non-exact match"
                      exit
                    end
                end
                puts "See: #{row['word']} #{see_wordids.inspect} #{see_words.inspect}"

                if @entries.find(
                  { 'korean.hangul' => kor['hangul'],
                    'senses.legacy.see_wordid' => see_wordids[0] }
                ).count == 1
                  puts "Trying to insert existing word #{kor['hangul']} with reference def #{row['def']}"
                  return nil, nil, nil
                end

                if sub_cursor.count >= 1
                    tags.push(@tag_refs['check_merge'])

                    _puts "\t#{row['word']} - #{row['def']} (#{ row['wordid'] })"
                    _puts "\t" + row.inspect
                    _puts "\n\n\n\n#{sub_cursor.count} results of sub cursor"
                    sub_cursor.each do |sub_row|
                        # Add definitions to the list of english definitions
                        _puts "\t#{sub_row['word']} - #{sub_row['def']} (#{ sub_row['wordid'] })"
                        _puts "\t" + sub_row.inspect
                        _puts "\n\nCalling self recursively with #{sub_row['def']} (from #{row['def']})"
                        _puts row.inspect
                        _puts sub_row.inspect
                        _puts "\n"
                        sub_kor, sub_senses, sub_tags = parse_clean_entry(see_coll, sub_row)
                        if sub_senses.length > 1
                            _puts "WARNING:"
                            _puts sub_kor.inspect
                            _puts sub_senses.inspect
                            _puts sub_tags .inspect
                            exit "Sub_senses really shouldn't have more than one result."
                        end
                        # Stuffing this in because it might be useful later
                        sub_senses[0]['legacy']['see_wordid'] = see_wordids #row['wordid']
                        if sub_kor['hangul'] != kor['hangul']
                            _puts "We have a serious problem, main hangul #{kor['hangul']} does not match sub korean #{sub_kor['hangul']}"
                        end
                        #puts "Sub: "
                        #puts "\t\t" + sub_senses.inspect
                        #puts "\t\t" + sub_tags.inspect
                        # Set union
                        senses = senses | sub_senses
                        #puts "Senses    see parent id: #{row['wordid']}"
                        #puts senses.inspect

                        tags = tags | sub_tags

                        #puts "\tFull: " + sub_row.inspect
                    end
                    #other = sub_cursor.next_document
                    #puts sub_cursor.count
                    #puts "\n\n"
                else
                    puts "Couldn't find a linked article marked '#{row['word']}' for '#{row['def']}'. This is a problem."
                    tags.push(@tag_refs['link_error'])
                end


                # The current definition is "see ..." so it's basically useless
                ##puts "Current def:"
                _puts row.inspect
                _puts "Obtained:"
                _puts kor.inspect
                _puts senses.inspect
                _puts tags.inspect
                _puts "\n\n\n\n"
                return kor, senses, tags
            end


            # Output is a single sense
            single_sense = Hash.new()

            # if any required fields are empty, flip out
            if (row['def'].nil? or row['def'] == "")
                tags.push(@tag_refs['english_undef'])
            end
            if (row['word'].nil? or row['word'] == "")
                tags.push(@tag_refs['hangul_undef'])
            end

            # m_korean always has uppercase first letters. It's annoying
            if (collection.name == "m_korean" && row['def'].class == String)
                # longest method ever.
                row['def'] = row['def'][0,1].downcase + row['def'][1,row['def'].length]
            end

            eng, en_tags = KDict::Migration.clean_english(row['def'])
            if en_tags.size > 0
                en_tags.each do |tag_str|
                    tags.push(@tag_refs[tag_str])
                end
            end
            single_sense['definitions'] = Hash.new
            single_sense['definitions']['english'] = Array.new
            single_sense['definitions']['english'].push(eng)


            if (collection.name != "p_korean")
                hanja, tag  = KDict::Migration.clean_hanja(row['hanja'])
                if (hanja != "")
                    single_sense['hanja'] = [ hanja ]
                end
                if tag
                    tags.push(@tag_refs[tag])
                end
            end

            single_sense['pos'], tag = KDict::Migration.clean_pos(row['pos'])
            if tag
                tags.push(@tag_refs[tag])
            end
            if kor['hangul'] =~ /다\s*$/
                if (single_sense['pos'] !~ /^verb|adjective$/)
                    #puts "single_sense: " + kor['hangul'] + ' ' + single_sense['pos']
                    tags.push(@tag_refs['da_not_verb'])
                end
            end

            # Get rid of empty things
            row.each do |key, val|
                if (row['key'] == '\N')
                    row['key'] = nil
                end
            end

            #single_sense['submitter'] = 'Ruby migration tool'
            # TODO Do we want to change the way tags are being handled?
            #      Instead they could be set by running the Mongoose validation
            #      on each record, via Javascript
            single_sense['legacy'] = Hash.new
            single_sense['legacy']['wordid']    = row['wordid']
            single_sense['legacy']['submitter'] = row['submitter']
            single_sense['legacy']['table']     = collection.name
            # There's got to be a nicer way of doing ifdefs like this
            if !row['doe'].nil? && row['doe'] != ""
                single_sense['legacy']['doe']       = row['doe']
            end
            if !row['pos'].nil? && row['pos'] != ""
                single_sense['legacy']['pos']       = row['pos']
            end
            if !row['posn'].nil? && row['posn'] != ""
                single_sense['legacy']['posn']      = row['posn']
            end
            if !row['class'].nil? && row['class'] != ""
                single_sense['legacy']['class']     = row['class']
            end
            if !row['level'].nil? && row['level'] != ""
                single_sense['legacy']['level']     = row['level']
            end
            if !row['frequency'].nil? && row['frequency'] != ""
                single_sense['legacy']['frequency']       = row['frequency']
            end
            if !row['syn'].nil? && row['syn'] != ""
                single_sense['legacy']['syn']       = row['syn']
            end

            return kor, [ single_sense ], tags
        end
        def self.integers_to_korean(input)
            done = input.gsub(/(\\{1,2}\d{3})+/) do |match|
                match.scan(/\d+/).map { |n| n.to_i(8) }.pack("C*").force_encoding('utf-8')
            end
            return done
        end

        def self.clean_hangul(raw)
            tag = false
            if (raw.class == Fixnum)
                clean = raw.to_s
            else
                clean = String.new(raw)
            end

            # God knows what we have in here
            if !all_something?(clean, @@hangul_range)
                tag = 'korean_content'
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
                tags.push 'non-ascii'
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
            clean.gsub!(/([,.!?;:])(\S)/, '\1 \2')
            clean.gsub!(/\s+([,.!?;:])/, '\1')


            # This comes up quite a lot
            clean.gsub!(/(^|\s)sb/, ' somebody')
            clean.gsub!(/^\s+/, '')
            clean.gsub!('sth', 'something')

            # Leading spaces before a 's
            clean.gsub!(/\s+'s\s/, "'s ")

            clean.gsub!(/\si\s/, ' I ')

            # If we have weird parens
            if (clean =~ /[\[\]\{\}]/)
                tags.push 'english-parens'
            end

            # goddamn backslashes
            if (clean =~ /\\/)
                tags.push 'english_backslashes'

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
                tags.push 'english_acronym'
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
            #when 6
            #    # ???
            when 7, "지"
                pos = 'location'
            when 9, "수"
                pos = 'number'
            #when 10
            #    tag = true
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
            #when "도" 
            #when "보" # helping verb
            #when "불" # ??
            #when "형" # adj
            #when "curious" 
            end

            if pos.nil?
                tag = 'unknown_pos'
            end

            return pos, tag
        end

        def self.clean_hanja(raw)
            clean = String.new(raw)
            tag = false

            # Destroy stupid backslashes
            clean.gsub!(/\\r/, '')
            clean.gsub!(/\\t/, '')

            clean = kill_html(clean)

            if clean != "" && !all_something?(clean, @@hanja_range)
                tag = "non_hanja"
                #puts "#{clean} contains non-hanja!"
            end

            return clean, tag
        end

        def self.all_something?(string, range)
            all_something = true
            string.each_char do |c|
                code = c.unpack('U*').first
                #puts code
                found = false
                range.each do |start, finish|
                    #puts start, finish
                    if code >= start && code <= finish
                        found = true
                        break
                    end
                end

                if !found
                    all_hanja = false
                    break
                end
            end

            return all_something
        end

        # Hanja can be a clever mix of HTML with JS and HTML elements within the JS
        # We need the power of an HTML parser
        def self.kill_html(raw)
            raw.gsub!('"oak"', 'oak') # wordid: 222875 has invalid HTML. Awful hack
            return Hpricot(raw).inner_text
        end


        def self.post_entry(entry)
            blah = JSON.generate(entry)
            #1: Simple POST
            # using block
            res = Net::HTTP.post_form(URI.parse('http://localhost:3000/entries/create_raw'), 'entry_json' => blah)
            #uri  = URI.parse('http://localhost:3000/entries/create_raw')
            #res = Net::HTTP.start(uri.host, uri.port) do |http|
            #    http.request_post('entries/create_raw', entry) do |response|
            #        p response.status
            #        p response['content-type']
            #        response.read_body do |str|   # read body now
            #            print str
            #        end
            #    end
            #end
            
            #request = Net::HTTP::Post.new(uri.request_uri)
            #request.set_form_data({'entry' => entry})
            #response = http.request(request)
            case res
            when Net::HTTPSuccess, Net::HTTPRedirection
            else
                puts res.error!
                puts entry
                puts blah
                exit
            end
        end
    end
end



if ARGV[0] == 'go'
    puts "GOING"

    migrate = KDict::Migration.new()
    migrate.import_all()
else
    puts "WARNING: This tool will drop any existing collections in the db 'kdict' called:"
    puts " - entries"
    puts " - updates"
    puts " - users"
    puts " - tags"
    puts "Run with 'ruby migrate.rb go'"
    puts "(requires Ruby >= 1.9.2)"
end



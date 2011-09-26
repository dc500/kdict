# encoding: utf-8
require '/Users/ben/Dropbox/Programming/fun/kdict/scripts/migrate.rb'
require 'pp'

korean_mess_test = [
    [ "Scrabble \\\\354\\\\203\\\\201\\\\355\\\\221\\\\234\\\\353\\\\252\\\\205",
      "Scrabble \354\203\201\355\221\234\353\252\205" ],
    [ "prolamin\\\\343\\\\204\\\\267",
      "prolamin\343\204\267" ],
    [ "\\\\354\\\\202\\\\254\\\\353\\\\236\\\\214...\\\\354\\\\227\\\\220\\\\352\\\\262\\\\214",
      "\354\202\254\353\236\214...\354\227\220\352\262\214" ],
    [ "to fix \\352\\265\\220\\354\\240\\225\\353\\263\\264\\353\\213\\244.",
      "to fix \352\265\220\354\240\225\353\263\264\353\213\244."],
    [ "\\354\\202\\254\\353\\236\\214.. \354\\227\\220\\352\\262\\214",
      "\354\202\254\353\236\214.. \354\227\220\352\262\214"],
]


clean_eng_test = [
    [
        # make sure we preserve leading parens when there's a closing paren
        "(God) save (bless) the  mark",
        "(God) save (bless) the mark"
    ],
    [ "U.N.E.F.", "UNEF" ],
    [ "foo,bar is,great", "foo, bar is, great" ], # make sure we have proper commas
    [ "spaces  ? before punct", "spaces? before punct" ],
    [ "hello (what?) , yeah", "hello (what?), yeah" ],
    [ "stupid?punctuation without spaces", "stupid? punctuation without spaces" ], # make sure we have proper commas
    [ "stupid  double space   and three", "stupid double space and three" ], # overeager sb->somebody
    [ "Christmasbox", "Christmasbox" ], # overeager sb->somebody
    [ "sb who is always complaining", "somebody who is always complaining" ],
    [ "fasb is great", "fasb is great" ],
    [ "to inform on sb, nark, squeal on sb to the police", "to inform on somebody, nark, squeal on somebody to the police" ],
    [ %q{Please see <a href='http://ezcorean.com//index.php?level=2&cfile=bb_index.php&subaction=vthread&topic=70102&forum=25&from_lang=korean&switch=p&old_cfile=mod_pager&ocfbv=browse_word&dpjs=1&entrant=&wordid=102&pos=1&posn=1&hmp_offset=8'>도</a> meaning <b>even</b>. This means, however, <i>even if you don't do that thing</i>},
        %q{Please see 도 meaning "even". This means, however, "even if you don't do that thing"}
    ]
]


evil_hanja_test = [
    [ %q{<a href="http://ezcorean.com/bb_index.php?subaction=vthread&topic=91062&forum=17&switch=h&level=3II" onMouseover="return overlib('하늘 건 (the sky) or 마를 건 (마르다: to dry )')" onMouseOut="nd();">乾</a><a href="http://ezcorean.com/bb_index.php?subaction=vthread&topic=91468&forum=17&switch=h&level=3I" onMouseover="return overlib('땅곤 (the earth)')" onMouseOut="nd();">坤</a><a href="http://ezcorean.com/bb_index.php?subaction=vthread&topic=93559&forum=17&switch=h&level=8" onMouseover="return overlib('일 1')" onMouseOut="nd();">一</a><a href="http://ezcorean.com/bb_index.php?subaction=vthread&topic=93305&forum=17&switch=h&level=1" onMouseover="return overlib('던질척')" onMouseOut="nd();">擲</a>},
        '乾坤一擲'
    ],
    [ %q{<a href="http://ezcorean.com/bb_index.php?subaction=vthread&topic=90343&forum=17&switch=h&level=5" onMouseover="return overlib('서로 상 reciprocal')" onMouseOut="nd();">相</a><a href="http://ezcorean.com/bb_index.php?subaction=vthread&topic=91252&forum=17&switch=h&level=3II" onMouseover="return overlib('탈승 (타다: to get in/on a train/bus/horse)')" onMouseOut="nd();">乘</a><a href="http://ezcorean.com/bb_index.php?subaction=vthread&topic=90447&forum=17&switch=h&level=5" onMouseover="return overlib('본받을효 (本— to follow the exampleof/model oneself after) or 효험 효 (效驗 the quality/virtue of being efficacious)')" onMouseOut="nd();">效</a><a href="http://ezcorean.com/bb_index.php?subaction=vthread&topic=90116&forum=17&switch=h&level=6" onMouseover="return overlib('실과 과.  실과 is <b>a practical course, a practicum</b>.  also 결과 과')" onMouseOut="nd();">果</a>},
        '相乘效果'
    ],
    [ %q{<a href="http://ezcorean.com/bb_index.php?subaction=vthread&topic=93063&forum=17&switch=h&level=1" onMouseover="return overlib('옥이름완 (this is the hanja for people with the name of oak)')" onMouseOut="nd();">琓</a>},
        '琓'
    ],
]


def test(data, function)
    data.each do |input, expected|
        changed, flags = function.call(input)
        pp input, expected, changed
        if (changed == expected)
            puts 'PASS!!'
        else
            puts 'FAIL'
        end

        puts "\n\n\n\n"
    end
end

test(evil_hanja_test, KDict::Migration.method(:clean_hanja))
test(clean_eng_test, KDict::Migration.method(:clean_english))
exit
test(korean_mess_test, KDict::Migration.method(:integers_to_korean))
test(korean_mess_test, KDict::Migration.method(:clean_english))


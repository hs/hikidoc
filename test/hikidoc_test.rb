require "test/unit"
rootdir = "#{File::dirname(__FILE__)}/.."
require "#{rootdir}/lib/hikidoc"

class HikiDocTestCase < Test::Unit::TestCase
  def test_escape
    assert_convert(%Q|<p>&lt;s&gt;foo</p>\n|,
                   %Q|<s>foo|)
    assert_convert(%Q|<p>&amp;lt;foo</p>\n|,
                   %Q|&lt;foo|)
    assert_convert(%Q|<p>"\\"foo</p>\n|,
                   %q|\"\"foo|)
    assert_convert(%Q|<p>\\foo</p>\n|,
                   %q|\\\\foo|)
    assert_convert(%Q|<p>[str]foo</p>\n|,
                   %q|\\[str]foo|)
    assert_convert(%Q|<p>! foo</p>\n|,
                   %q|\\! foo|)
    assert_convert(%Q|<p>* foo</p>\n|,
                   %q|\\* foo|)
    assert_convert(%Q|<p># foo</p>\n|,
                   %q|\\# foo|)
    assert_convert(%Q|<p>// コメント</p>\n|,
                   %q|\\// コメント|)
    assert_convert(%Q|<p>----</p>\n|,
                   %q|\\----|)
    assert_convert(%Q|<p>;foo</p>\n|,
                   %q|\\;foo|)
    assert_convert(%Q|<p>:foo</p>\n|,
                   %q|\\:foo|)
    assert_convert(%Q(<p>||foo</p>\n),
                   %q(\\||foo))
    assert_convert(%Q|<p>{foo}</p>\n|,
                   %q|\\{foo}|)
    assert_convert(%Q|<p>&lt;&lt;&lt;d</p>\n|,
                   %q|\\<<<d|)
  end

  def test_attr
    # class
    assert_convert(%Q|<p class="cls">foo</p>\n|,
                   "[cls]\nfoo")
    assert_convert(%Q|<p class="cls">foo</p>\n|,
                   %Q|[ cls]\nfoo|)
    assert_convert(%Q|<p class="cls">foo</p>\n|,
                   %Q|[cls ]\nfoo|)
    assert_convert(%Q|<p class="cls">foo</p>\n|,
                   %Q| [cls]\nfoo|)
    # valid chars in class
    assert_convert(%Q|<p class="c-l:s.1_0">foo</p>\n|,
                   "[c-l:s.1_0]\nfoo")
    # multi class
    assert_convert(%Q|<p class="cls1 cls2">foo</p>\n|,
                   "[cls1 cls2]\nfoo")

    # title
    assert_convert("<p title=\"foo\">bar</p>\n",
                   %Q|["foo"]\nbar|)
    assert_convert(%Q|<p title="foo">bar</p>\n|,
                   %Q|[ "foo"]\nbar|)
    assert_convert(%Q|<p title="foo">bar</p>\n|,
                   %Q|["foo" ]\nbar|)
    assert_convert("<p title=\"foo\">bar</p>\n",
                   %Q|[,"foo"]\nbar|)
    ## comma in title
    assert_convert(%Q|<p title=\"foo,bar\">baz</p>\n|,
                   %Q|[,"foo,bar"]\nbaz|)
    ## escape double quotation marks
    assert_convert("<p title=\"&quot;foo&quot;\">bar</p>\n",
                   %Q|[""foo""]\nbar|)
    assert_convert("<p title=\"f&quot;o&quot;o\">bar</p>\n",
                   %Q|["f"o"o"]\nbar|)
    ## ignore modifier
    assert_convert("<p title=\"f{'o'}o\">bar</p>\n",
                   %Q|["f{'o'}o"]\nbar|)
    ## ignore plugin
    assert_convert("<p title=\"f{{o}}o\">bar</p>\n",
                   %Q|["f{{o}}o"]\nbar|)

    # class and title
    assert_convert("<p class=\"cls\" title=\"foo\">bar</p>\n",
                   %Q|[cls,"foo"]\nbar|)
    assert_convert("<p class=\"cls\" title=\"foo\">bar</p>\n",
                   %Q|[ cls,"foo"]\nbar|)
    assert_convert("<p class=\"cls\" title=\"foo\">bar</p>\n",
                   %Q|[cls,"foo" ]\nbar|)
    assert_convert("<p class=\"cls\" title=\"foo\">bar</p>\n",
                   %Q|[cls ,"foo"]\nbar|)
    assert_convert("<p class=\"cls\" title=\"foo\">bar</p>\n",
                   %Q|[cls, "foo"]\nbar|)
    assert_convert("<p class=\"cls\" title=\"foo\">bar</p>\n",
                   %Q|[cls , "foo"]\nbar|)

    # enable_id
    assert_convert(%Q|<p id="id">foo</p>\n|,
                   "[id]\nfoo", { :enable_id => true })
    assert_convert(%Q|<p id="id">foo</p>\n|,
                   "[ id ]\nfoo", { :enable_id => true })
    ## multi id
    assert_convert(%Q|<p id="id1 id2">foo</p>\n|,
                   "[id1 id2]\nfoo", { :enable_id => true })
    ## id & class
    assert_convert(%Q|<p id="id" class="cls">foo</p>\n|,
                   "[id,cls]\nfoo", { :enable_id => true })
    assert_convert(%Q|<p id="id" class="cls">foo</p>\n|,
                   "[ id , cls ]\nfoo", { :enable_id => true })
    ## id & class & title
    assert_convert(%Q|<p id="id" class="cls" title="title">foo</p>\n|,
                   %Q|[id,cls,"title"]\nfoo|, { :enable_id => true })
    assert_convert(%Q|<p id="id" class="cls" title="title">foo</p>\n|,
                   %Q|[ id , cls , "title" ]\nfoo|, { :enable_id => true })
    ## empty attributes
    assert_convert(%Q|<p title="title">foo</p>\n|,
                   %Q|["title"]\nfoo|, { :enable_id => true })
    assert_convert(%Q|<p id="id" title="title">foo</p>\n|,
                   %Q|[id,"title"]\nfoo|, { :enable_id => true })
    assert_convert(%Q|<p class="cls" title="title">foo</p>\n|,
                   %Q|[,cls,"title"]\nfoo|, { :enable_id => true })

    # invalid form
    ## no attributes
    assert_convert("<p>[]\nfoo</p>\n",
                   %Q|[]\nfoo|)
    assert_convert("<p>[,]\nfoo</p>\n",
                   %Q|[,]\nfoo|)
    ## illegal class name
    assert_convert(%Q|<p>[_cls]\nfoo</p>\n|,
                   "[_cls]\nfoo")
    assert_convert(%Q|<p>[0cls]\nfoo</p>\n|,
                   %Q|[0cls]\nfoo|)
    assert_convert(%Q|<p>[-cls]\nfoo</p>\n|,
                   %Q|[-cls]\nfoo|)
    assert_convert(%Q|<p>[cls1 0cls2]\nfoo</p>\n|,
                   "[cls1 0cls2]\nfoo")
    assert_convert(%Q|<p>[cls1 -cls2]\nfoo</p>\n|,
                   "[cls1 -cls2]\nfoo")
    ## lack of title
    assert_convert("<p>[cls,]\nfoo</p>\n",
                   %Q|[cls,]\nfoo|)
    ## title isn't enclosed in double quotation marks
    assert_convert(%Q!<p>[,foo]\nbar</p>\n!,
                   %Q|[,foo]\nbar|)
    assert_convert(%Q|<p>["tit]\nfoo</p>\n|,
                   %Q|["tit]\nfoo|)
    assert_convert(%Q|<p>[,"tit]\nfoo</p>\n|,
                   %Q|[,"tit]\nfoo|)
    assert_convert(%Q|<p>[tle"]\nfoo</p>\n|,
                   %Q|[tle"]\nfoo|)
    assert_convert(%Q|<p>[,tle"]\nfoo</p>\n|,
                   %Q|[,tle"]\nfoo|)
    assert_convert(%Q!<p>[cls,foo]\nbar</p>\n!,
                   %Q|[cls,foo]\nbar|)
    ## too much attributes
    assert_convert(%Q|<p>[,foo,"bar"]\nbaz</p>\n|,
                   %Q|[,foo,"bar"]\nbaz|)
    assert_convert(%Q!<p>[,foo,]\nbar</p>\n!,
                   %Q|[,foo,]\nbar|)
    ## wrong order
    assert_convert(%Q|<p>["title",cls]\nfoo</p>\n|,
                   %Q|["title",cls]\nfoo|)
    ## missing comma
    assert_convert(%Q|<p>[cls"title"]\nfoo</p>\n|,
                   %Q|[cls"title"]\nfoo|)
    ## missing bracket
    assert_convert("<p>[cls</p>\n",
                   %Q|[cls|)
    assert_convert("<p>cls]</p>\n",
                   %Q|cls]|)
    assert_convert("<p>[cls\nfoo</p>\n",
                   %Q|[cls\nfoo|)
    assert_convert("<p>cls]\nfoo</p>\n",
                   %Q|cls]\nfoo|)

    # security
    assert_convert(%Q|<p>[cl&lt;s&gt;]\nfoo</p>\n|,
                   %Q|[cl<s>]\nfoo|)
    assert_convert(%Q|<p>[cl"s"]\nfoo</p>\n|,
                   %Q|[cl"s"]\nfoo|)
    assert_convert(%Q|<p>[cl&amp;#34;s]\nfoo</p>\n|,
                   %Q|[cl&#34;s]\nfoo|)
    assert_convert(%Q|<p title="cl&lt;s&gt;">foo</p>\n|,
                   %Q|["cl<s>"]\nfoo|)
    assert_convert(%Q|<p title="cl&quot;s&quot;">foo</p>\n|,
                   %Q|["cl"s""]\nfoo|)
    assert_convert(%Q|<p title="cl&amp;lt;s">foo</p>\n|,
                   %Q|["cl&lt;s"]\nfoo|)
    assert_convert(%Q|<p title="cl&lt;s">foo</p>\n|,
                   %Q|["cl{&lt;}s"]\nfoo|)
    assert_convert(%Q|<p title="cl&quot;s">foo</p>\n|,
                   %Q|["cl{&quot;}s"]\nfoo|)
    assert_convert(%Q|<p title="cl{&amp;[t]quot;}s">foo</p>\n|,
                   %Q|["cl{&[t]quot;}s"]\nfoo|)
    assert_convert(%Q|<p title="c&lt;l&quot;s&gt;">foo</p>\n|,
                   %Q|["c<l{&quot;}s>"]\nfoo|)
  end

  def test_custom_attr
	# '('
    options = {:attr_prefix => '('}
    assert_convert(%Q|<p class="cls">foo</p>\n|,
                   "(cls)\nfoo",
                   options)
    assert_convert(%Q|<p>((cls))\nfoo</p>\n|,
                   "((cls))\nfoo",
                   options)

	# "'"
    options = {:attr_prefix => "'"}
    assert_convert(%Q|<p class="cls">foo</p>\n|,
                   "'cls'\nfoo",
                   options)
    assert_convert(%Q|<p>''cls''\nfoo</p>\n|,
                   "''cls''\nfoo",
                   options)

	# '`'
    options = {:attr_prefix => '`'}
    assert_convert(%Q|<p class="cls">foo</p>\n|,
                   "`cls'\nfoo",
                   options)
    assert_convert(%Q|<p>``cls''\nfoo</p>\n|,
                   "``cls''\nfoo",
                   options)

	# '|'
    options = {:attr_prefix => '|'}
    assert_convert(%Q|<p class="cls">foo</p>\n|,
                   "|cls|\nfoo",
                   options)
    assert_convert(%Q|<table>\n<tr><td>cls</td><td>foo</td></tr>\n</table>\n|,
                   "||cls||foo",
                   options)

	# '<'
    options = {:attr_prefix => '<'}
    assert_convert(%Q|<p class="cls">foo</p>\n|,
                   "<cls>\nfoo",
                   options)
    assert_convert(%Q|<p>&lt;&lt;cls&gt;&gt;\nfoo</p>\n|,
                   "<<cls>>\nfoo",
                   options)
  end

  def test_reference
    # normal
    assert_convert(%Q|<p>&#34;</p>\n|,
                   %Q|{&#34;}|)

    # error
    assert_convert(%Q|<p>{&amp;34;}</p>\n|,
                   %Q|{&34;}|)
    assert_convert(%Q|<p>{&amp;&lt;s&gt;"foo";}</p>\n|,
                   %Q|{&<s>"foo";}|)
  end

  def test_block
    assert_convert(%Q|<div class="foo" title="bar,baz">\n<p>text</p>\n</div>\n|,
                   %Q|<<<[foo,"bar,baz"]\ntext\n>>>|)
    # ignore nonsense div block
    assert_convert("<p>foo</p>\n",
                   %Q|<<<\nfoo\n>>>|)

    assert_convert("<ul>\n<li><p>foo</p>\n</li>\n</ul>\n",
                   %Q|*(((\nfoo\n)))|)
    assert_convert("<ul>\n<li><p>foo</p>\n<p>bar</p>\n</li>\n</ul>\n",
                   %Q|*(((\nfoo\n\nbar\n)))|)
    assert_convert("<ul>\n<li>i(((</li>\n</ul>\n<p>foo</p>\n<p>bar\n)))</p>\n",
                   %Q|*i(((\nfoo\n\nbar\n)))|)
    assert_convert("<p>&lt;&lt;&lt;be\nfoo\n&gt;&gt;&gt;</p>\n",
                   %Q|<<<be\nfoo\n>>>|)

    # error
    assert_convert("<p>&lt;&lt;&lt;\nfoo</p>\n",
                   %Q|<<<\nfoo\n|)
    assert_convert("<p>&lt;&lt;&lt;[foo]\nfoo</p>\n",
                   %Q|<<<[foo]\nfoo\n|)
    assert_convert("<p>foo\n&gt;&gt;&gt;</p>\n",
                   %Q|\nfoo\n>>>|)

    assert_convert("<p>&lt;&lt;&lt;\nfoo\n&gt;&gt;&gt;a</p>\n",
                   %Q|<<<\nfoo\n>>>a|)
    assert_convert(%Q|<div class="foo">\n<p>&gt;&gt;&gt;a</p>\n</div>\n|,
                   %Q|<<<[foo]\n\n>>>a\n>>>|)
    assert_convert(%Q|<p>&lt;&lt;&lt;\\[foo,\"bar,baz\"]\ntext\n&gt;&gt;&gt;</p>\n|,
                   %Q|<<<\\[foo,"bar,baz"]\ntext\n>>>|)
  end

  def test_paragraph
    assert_convert("<p>foo</p>\n", "foo")
    assert_convert("<p>foo\nbar</p>\n", "foo\nbar")

    assert_convert("<p>foo</p>\n<p>bar</p>\n",
                   "foo\n\nbar")
    assert_convert("<p>foo</p>\n<p>bar</p>\n",
                   "foo\r\n\r\nbar")

    assert_convert("<p>foo </p>\n<p>b a r </p>\n",
                   "foo \n\nb a r ")

    # break line
    assert_convert("<p>foo<br />\nbar</p>\n", "foo\n bar")
    # ignore break line at the first line of paragraph
    assert_convert("<p>foo</p>\n", " foo")
  end

  def test_paragraph_with_attr
    assert_convert("<p class=\"cls\">foo</p>\n",
                   "[cls]\nfoo\n")
    assert_convert("<p class=\"cls\">foo\nbar</p>\n",
                   "[cls]\nfoo\nbar")
    assert_convert("<p class=\"cls\">foo<br />\nbar</p>\n",
                   "[cls]\nfoo\n bar")

    assert_convert("<p><span class=\"cls\">foo</span></p>\n",
                   %Q|[cls]foo\n|)
    assert_convert("<p class=\"cls1\"><span class=\"cls2\">foo</span></p>\n",
                   %Q|[cls1]\n[cls2]foo\n|)
    assert_convert("<p><span class=\"cls\">foo</span>\nbar</p>\n",
                   %Q|[cls]foo\nbar|)
    assert_convert("<p>foo\n<span class=\"cls\">bar</span>\nbaz</p>\n",
                   %Q|foo\n[cls]bar\nbaz|)
    assert_convert("<p><span class=\"cls1\">foo</span>\n<span class=\"cls2\">bar</span></p>\n",
                   %Q|[cls1]foo\n[cls2]bar|)

    assert_convert("<p><span class=\"cls\">foo</span><br />\nbar</p>\n",
                   %Q|[cls]foo\n bar|)
    assert_convert("<p><span class=\"cls1\">foo</span><br />\n" +
                   "<span class=\"cls2\">bar</span></p>\n",
                   %Q|[cls1]foo\n [cls2]bar|)
  end

  def test_header
    assert_convert("<h1>foo</h1>\n", "!foo")
    assert_convert("<h1>foo<br />bar</h1>\n", "!foo\n bar")
    assert_convert("<h1><em>foo</em></h1>\n", "!{'foo'}")
    assert_convert("<h1>foo<br />bar</h1>\n", "! foo\n bar")
    assert_convert("<h1>&lt;&lt;&lt;b</h1>\n<p>foo\n&gt;&gt;&gt;</p>\n",
                   "!<<<b\nfoo\n>>>")
    assert_convert("<h2>foo</h2>\n", "!! foo")
    assert_convert("<h3>foo</h3>\n", "!!!foo")
    assert_convert("<h4>foo</h4>\n", "!!!! foo")
    assert_convert("<h5>foo</h5>\n", "!!!!!foo")
    assert_convert("<h6>foo</h6>\n", "!!!!!! foo")
    assert_convert("<h6>! foo</h6>\n", "!!!!!!! foo")

    assert_convert("<h1>foo</h1>\n<h2>bar</h2>\n",
                   "!foo\n!!bar")
  end

  def test_header_with_attribute
    assert_convert("<h1 class=\"cls\">foo</h1>\n", "![cls]foo")
    assert_convert("<h1 title=\"title\">foo</h1>\n", %Q|!["title"]foo|)
    assert_convert("<h1 title=\"title\">foo</h1>\n", %Q|![,"title"]foo|)
    assert_convert("<h1 class=\"cls\" title=\"title\">foo</h1>\n", %Q|![cls,"title"]foo|)

    assert_convert("<h1 id=\"id\">foo</h1>\n", "![id]foo", { :enable_id => true })
    assert_convert("<h1 class=\"cls\">foo</h1>\n", "![,cls]foo", { :enable_id => true })
    assert_convert("<h1 title=\"title\">foo</h1>\n", %Q|!["title"]foo|, { :enable_id => true })
    assert_convert("<h1 id=\"id\" class=\"cls\">foo</h1>\n", "![id,cls]foo", { :enable_id => true })

    # not attribute
    assert_convert(%Q!<h1>[cls,"title"]foo</h1>\n!, %Q|! [cls,"title"]foo|)
  end

  def test_link
    assert_convert(%Q|<p><a href="http://hikiwiki.org/">http://hikiwiki.org/</a></p>\n|,
                   "http://hikiwiki.org/")
    assert_convert(%Q|<p><a href="http://hikiwiki.org/">http://hikiwiki.org/</a></p>\n|,
                   "[[http://hikiwiki.org/]]")
    assert_convert(%Q|<p><a href="http://hikiwiki.org/">Hiki</a></p>\n|,
                   "[[Hiki|http://hikiwiki.org/]]")
    assert_convert(%Q|<p><a href="/hikiwiki.html">Hiki</a></p>\n|,
                   "[[Hiki|http:/hikiwiki.html]]")
    assert_convert(%Q|<p><a href="hikiwiki.html">Hiki</a></p>\n|,
                   "[[Hiki|http:hikiwiki.html]]")

    assert_convert(%Q|<p><a href="http://hikiwiki.org/ja/?c=edit;p=Test">| +
                   %Q|http://hikiwiki.org/ja/?c=edit;p=Test</a></p>\n|,
                   "http://hikiwiki.org/ja/?c=edit;p=Test")

    assert_convert(%Q|<p><a href="http://hikiwiki.org/ja/?c=edit&amp;p=Test">| +
                   %Q|http://hikiwiki.org/ja/?c=edit&amp;p=Test</a></p>\n|,
                   "http://hikiwiki.org/ja/?c=edit&p=Test")

    assert_convert(%Q|<p><a href="%CB%EE">Tuna</a></p>\n|,
                   "[[Tuna|%CB%EE]]")
    assert_convert(%Q|<p><a href="&quot;&quot;">""</a></p>\n|,
                   '[[""]]')
    assert_convert(%Q|<p><a href="%22">%22</a></p>\n|,
                   "[[%22]]")
    assert_convert(%Q|<p><a href="&amp;">&amp;</a></p>\n|,
                   "[[&]]")
    assert_convert(%Q|<p><a href="aa">aa</a>bb<a href="cc">cc</a></p>\n|,
                   "[[aa]]bb[[cc]]")
    assert_convert(%Q!<p><a href="aa">a|a</a></p>\n!,
                   "[[a|a|aa]]")
  end

  def test_link_with_attr
    assert_convert(%Q|<p><a href="http://hikiwiki.org/" class="cls" title="title">http://hikiwiki.org/</a></p>\n|,
                   %Q<[[[ cls , "title" ]http://hikiwiki.org/]]>)
    assert_convert(%Q|<p><a href="http://hikiwiki.org/" class="cls" title="title">Hiki</a></p>\n|,
                   %Q<[[[ cls , "title"]Hiki|http://hikiwiki.org/]]>)
    assert_convert(%Q|<p><a href="http://hikiwiki.org/" id="id" class="cls" title="foo">http://hikiwiki.org/</a></p>\n|,
                   %Q|[[[ id , cls , "foo" ]http://hikiwiki.org/]]|, { :enable_id => true })
    assert_convert(%Q|<p><a href="http://hikiwiki.org/" id="id" class="cls" title="title">Hiki</a></p>\n|,
                   %Q<[[[ id , cls , "title" ]Hiki|http://hikiwiki.org/]]>, { :enable_id => true })

    assert_convert(%Q|<p><span class="cls" title="title"><a href="http://hikiwiki.org/">http://hikiwiki.org/</a></span></p>\n|,
                   %Q|[ cls , "title" ]http://hikiwiki.org/|)

    # not attribute
    assert_convert(%Q|<p><a href=" [ cls , &quot;title&quot; ]http://hikiwiki.org/"> [ cls , "title" ]http://hikiwiki.org/</a></p>\n|,
                   %Q<[[ [ cls , "title" ]http://hikiwiki.org/]]>)
  end

  def test_image_link
    assert_convert(%Q|<p><img src="http://hikiwiki.org/img.png" alt="" /></p>\n|,
                   "http://hikiwiki.org/img.png")
    assert_convert(%Q|<p><img src="http://hikiwiki.org:80/img.png" alt="" /></p>\n|,
                   "http://hikiwiki.org:80/img.png")

    assert_convert(%Q|<p><img src="/img.png" alt="" /></p>\n|,
                   "http:/img.png")
    assert_convert(%Q|<p><img src="img.png" alt="" /></p>\n|,
                   "http:img.png")

    assert_convert(%Q|<p><img src="http://hikiwiki.org/img.png" alt="" /></p>\n|,
                   "[[http://hikiwiki.org/img.png]]")
    assert_convert(%Q|<p><a href="http://hikiwiki.org/img.png">http://hikiwiki.org/img.png</a></p>\n|,
                   "[[http://hikiwiki.org/img.png]]",
                   :allow_bracket_inline_image => false)

    assert_convert(%Q|<p><img src="http://hikiwiki.org/img.png" alt="img" /></p>\n|,
                   "[[img|http://hikiwiki.org/img.png]]")
    assert_convert(%Q|<p><a href="http://hikiwiki.org/img.png">img</a></p>\n|,
                   "[[img|http://hikiwiki.org/img.png]]",
                   :allow_bracket_inline_image => false)
  end

  def test_image_link_with_attr
    assert_convert(%Q|<p><img src="http://hikiwiki.org/img.png" alt="" class="cls" title="title" /></p>\n|,
                   %Q|[[[ cls , "title" ]http://hikiwiki.org/img.png]]|)
    assert_convert(%Q|<p><img src="http://hikiwiki.org/img.png" alt="" id="id" class="cls" title="title" /></p>\n|,
                   %Q|[[[ id , cls , "title" ]http://hikiwiki.org/img.png]]|,
                   { :enable_id => true })

    assert_convert(%Q|<p><span class="cls" title="title"><img src="http://hikiwiki.org/t.jpg" alt="" /></span></p>\n|,
                   %Q|[ cls , "title" ]http://hikiwiki.org/t.jpg|)

    # not attribute
    assert_convert(%Q|<p><img src=" [ cls , &quot;title&quot; ]http://hikiwiki.org/img.png" alt="" /></p>\n|,
                   %Q|[[ [ cls , "title" ]http://hikiwiki.org/img.png]]|)
  end

  def test_inter_wiki_name
    assert_convert("<p><a href=\"scheme:keyword\">scheme:keyword</a></p>\n",
                   "[[scheme:keyword]]")
    assert_convert("<p><a href=\"scheme:keyword\">label</a></p>\n",
                   "[[label|scheme:keyword]]")
  end

  def test_wiki_name
    assert_convert("<p><a href=\"WikiName\">WikiName</a></p>\n",
                   "WikiName")
    assert_convert("<p><a href=\"HogeRule1\">HogeRule1</a></p>\n",
                   "HogeRule1")

    assert_convert("<p><a href=\"WikiName1WikiName2\">WikiName1WikiName2</a></p>\n",
                   "WikiName1WikiName2")
    assert_convert("<p><a href=\"WikiName1\">WikiName1</a> " +
                      "<a href=\"WikiName2\">WikiName2</a></p>\n",
                   "WikiName1 WikiName2")

    assert_convert("<p>NOTWIKINAME</p>\n",
                   "NOTWIKINAME")
    assert_convert("<p>NOT_WIKI_NAME</p>\n",
                   "NOT_WIKI_NAME")
    assert_convert("<p>WikiNAME</p>\n",
                   "WikiNAME")
    assert_convert("<p>fooWikiNAME</p>\n",
                   "fooWikiNAME")

    assert_convert("<p>RSSPage</p>\n",
                   "RSSPage")
    assert_convert("<p><a href=\"RSSPageName\">RSSPageName</a></p>\n",
                   "RSSPageName")
  end

  def test_wiki_name_with_attr
    assert_convert(%Q|<p><span class="foo"><a href=\"WikiName\">WikiName</a></span></p>\n|,
                   "[foo]WikiName")
  end

  def test_not_wiki_name
    assert_convert("<p>WikiName</p>\n",
                   "^WikiName")
    assert_convert("<p>^<a href=\"WikiName\">WikiName</a></p>\n",
                   "^WikiName",
                   use_not_wiki_name: false)
    assert_convert("<p>^WikiName</p>\n",
                   "^WikiName",
                   use_wiki_name: false)
    assert_convert("<p>^WikiName</p>\n",
                   "^WikiName",
                   use_wiki_name: false,
                   use_not_wiki_name: false)
    assert_convert("<p>foo WikiName bar</p>\n",
                   "foo ^WikiName bar")
  end

  def test_use_wiki_name_option
    assert_convert("<p><a href=\"WikiName\">WikiName</a></p>\n",
                   "WikiName")
    assert_convert("<p>WikiName</p>\n",
                   "WikiName",
                   use_wiki_name: false)
  end

  def test_comment
    assert_convert("", "// foo")
    assert_convert("", "// foo\n")
  end

  def test_hrules
    assert_convert("<hr />\n", "----")
    assert_convert("<p>----a</p>\n", "----a")
  end

  def test_hrules_with_attr
    assert_convert(%Q|<hr class="cls" title="title" />\n|, %Q|----[ cls , "title" ]|)
    assert_convert(%Q|<hr class="cls" title="title" />\n|, %Q|[ cls , "title" ]\n----|)

    assert_convert(%Q|<hr id="id" />\n|,
                   %Q|[id]\n----|,
                   { :enable_id => true })
    assert_convert(%Q|<hr id="id" />\n|,
                   %Q|----[id]|,
                   { :enable_id => true })

    # not attribute
    assert_convert(%Q|<p>---- [ cls , "title" ]</p>\n|, %Q|---- [ cls , "title" ]|)
  end

  def test_list
    # normal
    assert_convert("<ul>\n<li>foo</li>\n</ul>\n",
                   "* foo")
    assert_convert("<ul>\n<li>foo</li>\n</ul>\n",
                   "*foo")
    assert_convert("<ul>\n<li>foo</li>\n<li>bar</li>\n</ul>\n",
                   "* foo\n* bar")
    # sandwich between paragraphs
    assert_convert("<p>foo</p>\n<ul>\n<li>bar</li>\n</ul>\n<p>baz</p>\n",
                   "foo\n* bar\nbaz")

    # linline element
    assert_convert("<ul>\n<li>foo<del>bar</del>baz</li>\n</ul>\n",
                   "* foo{=bar=}baz")

    # breakline
    assert_convert("<ul>\n<li>foo<br />bar<br />baz</li>\n</ul>\n<p>text</p>\n",
                   "* foo\n bar\n baz\ntext")
    assert_convert("<ul>\n<li>foo<br />bar</li>\n<li>baz</li>\n</ul>\n",
                   "* foo\n bar\n* baz")
    assert_convert("<ul>\n<li>foo<br />b<del>bar</del>r</li>\n</ul>\n",
                   "* foo\n b{=bar=}r")

    # change level
    assert_convert("<ul>\n<li>foo<ul>\n<li>bar</li>\n</ul></li>\n</ul>\n<p>text</p>\n",
                   "* foo\n** bar\ntext")
    assert_convert("<ul>\n<li>foo<ul>\n<li>foo</li>\n</ul></li>\n<li>bar</li>\n</ul>\n",
                   "* foo\n** foo\n* bar")
    assert_convert("<ul>\n<li>foo<ul>\n<li><ul>\n<li>bar</li>\n</ul></li>\n</ul></li>\n<li>baz</li>\n</ul>\n",
                   "* foo\n*** bar\n* baz")

    # breakline in nested list
    assert_convert("<ul>\n<li>foo<ul>\n<li>bar<br />baz</li>\n</ul></li>\n</ul>\n<p>text</p>\n",
                   "* foo\n** bar\n baz\ntext")

    # change list type
    assert_convert("<ul>\n<li>foo</li>\n</ul><ol>\n<li>bar</li>\n</ol>\n",
                   "* foo\n# bar")
    assert_convert("<ul>\n<li>foo<ol>\n<li>foo</li>\n</ol></li>\n<li>bar</li>\n</ul>\n",
                   "* foo\n## foo\n* bar")
  end

  def test_list_with_attr
    # basic
    assert_convert(%Q|<ul>\n<li class="cls" title="title">foo</li>\n</ul>\n|,
                   %Q|*[ cls , "title" ]foo|)
    assert_convert(%Q|<ul>\n<li class="cls" title="title">foo</li>\n<li class=\"cls2\" title=\"title2\">bar</li>\n</ul>\n|,
                   %Q|*[ cls , "title" ]foo\n*[cls2,"title2"] bar|)

    # set attributes to ul/li tag
    assert_convert(%Q|<ul class="ul_cls" title="ul_title">\n<li class="li_cls" title="li_title">foo</li>\n</ul>\n|,
                   %Q|*[ ul_cls , "ul_title" ]\n*[ li_cls , "li_title" ]foo|)
    assert_convert(%Q|<ul class="ul_cls" title="ul_title">\n<li class="li_cls" title="li_title">foo</li>\n</ul>\n|,
                   %Q|[ ul_cls , "ul_title" ]\n*[ li_cls , "li_title" ]foo|)

    # change ul attribute
    assert_convert(%Q|<ul>\n<li>foo</li>\n</ul><ul class="ul_cls" title="ul_title">\n<li class="li_cls" title="li_title">bar</li>\n<li>baz</li>\n</ul>\n|,
                   %Q|* foo\n*[ ul_cls , "ul_title"]\n*[ li_cls , "li_title" ]bar\n*baz|)

    # set attributes in nested list
    assert_convert(%Q|<ul>\n<li>foo<ul>\n<li><ul class="ul_cls" title="ul_title">\n<li class="li_cls" title="li_title">bar</li>\n</ul></li>\n</ul></li>\n<li>baz</li>\n</ul>\n|,
                   %Q|* foo\n***[ ul_cls, "ul_title"]\n***[ li_cls, "li_title"]bar\n* baz|)

    assert_convert(%Q!<ul>\n<li>foo</li>\n</ul><ol class="cls" title="title">\n<li>bar</li>\n</ol>\n!,
                   %Q|* foo\n#[ cls , "title"]\n# bar|)

    # enable_id
    ## basic
    assert_convert(%Q|<ul>\n<li id="id" class="cls" title="title">foo</li>\n</ul>\n|,
                   %Q|*[ id , cls , "title" ]foo|,
                   { :enable_id => true })
    assert_convert(%Q|<ul id="ul_id" class="ul_cls" title="ul_title">\n<li id="li_id" class="li_cls" title="li_title">foo</li>\n</ul>\n|,
                   %Q|[ ul_id , ul_cls , "ul_title" ]\n*[ li_id , li_cls , "li_title" ]foo|,
                   { :enable_id => true })

    # error
    assert_convert(%Q|<p><span class="cls">* foo</span></p>\n|,
                   "[cls]* foo")

    # not attribute
    assert_convert(%Q|<ul>\n<li>[ cls , "title" ]foo</li>\n</ul>\n|,
                   %Q|* [ cls , "title" ]foo|)
  end

  def test_list_with_block
    assert_convert("<ul>\n<li><p>foo\nbar\nbaz</p>\n</li>\n</ul>\n",
                   "* (((\nfoo\nbar\nbaz\n)))")
    assert_convert("<ul>\n<li><p>foo\nbar</p>\n</li>\n<li><p>baz</p>\n</li>\n</ul>\n",
                   "*(((\nfoo\nbar\n)))\n* (((\n\nbaz\n)))")

    # nesting
    assert_convert("<ul>\n<li><p>foo</p>\n<ul>\n<li><p>bar\nbaz</p>\n</li>\n</ul>\n</li>\n</ul>\n",
                   "*(((\nfoo\n*(((\nbar\nbaz\n)))\n)))")

    assert_convert("<ul>\n<li><blockquote>\n<p>foo\nbar\nbaz</p>\n</blockquote>\n</li>\n</ul>\n",
                   "*(((\n<<<b\nfoo\nbar\nbaz\n>>>\n)))")
    assert_convert(%Q|<ul>\n<li>| +
                   %Q|<blockquote>\n<p>foo\nbar</p>\n| +
                   %Q|<ol>\n<li>baz</li>\n</ol>\n| +
                   %Q|</blockquote>\n</li>\n| +
                   %Q|</ul>\n|,
                   "*(((\n<<<b\nfoo\nbar\n#baz\n>>>\n)))\n")

    # backtracking
    assert_convert("<ul>\n<li>(((</li>\n</ul>\n<p>foo\nbar\nbaz</p>\n",
                   "*(((\nfoo\nbar\nbaz")
    assert_convert(%Q|<ul>\n<li>(((</li>\n</ul>\n<p>foo</p>\n<ul>\n<li><p>bar\nbaz</p>\n</li>\n</ul>\n|,
                   "*(((\nfoo\n*(((\nbar\nbaz\n)))")
    assert_convert(%Q|<ul>\n<li>(((<br />foo</li>\n<li><p>bar\nbaz</p>\n</li>\n</ul>\n|,
                   "*(((\n foo\n*(((\nbar\nbaz\n)))")
  end

  def test_definition
    # normal
    assert_convert("<dl>\n<dt>a</dt>\n<dd>b</dd>\n</dl>\n",
                   ";a\n:b")
    # title only
    assert_convert("<dl>\n<dt>a</dt>\n<dt>b</dt>\n</dl>\n",
                   ";a\n;b")
    # data only
    assert_convert("<dl>\n<dd>a</dd>\n<dd>b</dd>\n</dl>\n",
                   ":a\n:b")
    # one liner
    assert_convert("<dl>\n<dt>a</dt>\n<dd>b</dd>\n</dl>\n",
                   ";a;:b")
    # ignore empty title/data in one liner
    assert_convert("<dl>\n<dt>a</dt>\n</dl>\n",
                   ";a;:")
    assert_convert("<dl>\n<dd>a</dd>\n</dl>\n",
                   ";;:a")
    # sandwich between paragraphs
    assert_convert("<p>pre</p>\n<dl>\n<dt>a</dt>\n<dd>b</dd>\n</dl>\n<p>post</p>\n",
                   "pre\n;a\n:b\npost")
    # breakline
    assert_convert("<dl>\n<dt>a<br />b</dt>\n</dl>\n",
                   ";a\n b")
    assert_convert("<dl>\n<dd>a<br />b</dd>\n</dl>\n",
                   ":a\n b")
    assert_convert("<dl>\n<dt>a<br />b</dt>\n<dd>c<br />d</dd>\n</dl>\n",
                   ";a\n b\n:c\n d")
    # colon in title
    assert_convert("<dl>\n<dt>a:b</dt>\n</dl>\n",
                   ";a:b")
    assert_convert("<dl>\n<dt>a:b</dt>\n<dd>c</dd>\n</dl>\n",
                   ";a:b;:c")
    # colon in data
    assert_convert("<dl>\n<dd>a:b</dd>\n</dl>\n",
                   ':a:b')
    assert_convert("<dl>\n<dt>a</dt>\n<dd>b:c</dd>\n</dl>\n",
                   ';a;:b:c')
  end

  def test_definition_with_attr
    # normal
    assert_convert(%Q|<dl class="dl_cls" title="dl_title">\n| +
                   %Q|<dt class="dt_cls" title="dt_title">a</dt>\n| +
                   %Q|<dd class="dd_cls" title="dd_title">b</dd>\n| +
                   %Q|</dl>\n|,
                   %Q|[ dl_cls , "dl_title" ]\n;[ dt_cls , "dt_title" ]a\n:[ dd_cls, "dd_title" ]b|)
    # one liner
    assert_convert(%Q|<dl class="dl_cls" title="dl_title">\n| +
                   %Q|<dt class="dt_cls" title="dt_title">a</dt>\n| +
                   %Q|<dd class="dd_cls" title="dd_title">b</dd>\n| +
                   %Q|</dl>\n|,
                   %Q|[ dl_cls , "dl_title" ]\n;[ dt_cls , "dt_title" ]a;:[ dd_cls, "dd_title" ]b|)

    # normal
    assert_convert(%Q|<dl id="dl_id" class="dl_cls" title="dl_title">\n| +
                   %Q|<dt id="dt_id" class="dt_cls" title="dt_title">a</dt>\n| +
                   %Q|<dd id="dd_id" class="dd_cls" title="dd_title">b</dd>\n| +
                   %Q|</dl>\n|,
                   %Q|[ dl_id , dl_cls , "dl_title" ]\n;[ dt_id , dt_cls , "dt_title" ]a\n:[ dd_id , dd_cls, "dd_title" ]b|,
                   { :enable_id => true })
    # one liner
    assert_convert(%Q|<dl id="dl_id" class="dl_cls" title="dl_title">\n| +
                   %Q|<dt id="dt_id" class="dt_cls" title="dt_title">a</dt>\n| +
                   %Q|<dd id="dd_id" class="dd_cls" title="dd_title">b</dd>\n| +
                   %Q|</dl>\n|,
                   %Q|[ dl_id , dl_cls , "dl_title" ]\n;[ dt_id , dt_cls , "dt_title" ]a;:[ dd_id , dd_cls, "dd_title" ]b|,
                   { :enable_id => true })

    # not attribute
    assert_convert(%Q|<dl>\n| +
                   %Q|<dt>[ dt_cls , "dt_title" ]a</dt>\n| +
                   %Q|<dd>[ dd_cls, "dd_title" ]b</dd>\n| +
                   %Q|</dl>\n|,
                   %Q|; [ dt_cls , "dt_title" ]a\n: [ dd_cls, "dd_title" ]b|)

  end

  def test_definition_with_link
    assert_convert("<dl>\n<dt><a href=\"http://hikiwiki.org/\">Hiki</a></dt>\n" +
                   "<dd>Website</dd>\n</dl>\n",
                   ";[[Hiki|http://hikiwiki.org/]];:Website")
    assert_convert("<dl>\n<dt>a</dt>\n" +
                   "<dd><a href=\"http://hikiwiki.org/\">Hiki</a></dd>\n" +
                   "</dl>\n",
                   ";a;:[[Hiki|http://hikiwiki.org/]]")
  end

  def test_definition_with_modifier
    # normal
    assert_convert("<dl>\n<dt><em>foo</em></dt>\n<dd><del>bar</del></dd>\n</dl>\n",
                   ";{'foo'}\n:{=bar=}")
    assert_convert("<dl>\n<dt>a<em>foo</em>a</dt>\n<dd>b<del>bar</del>b</dd>\n</dl>\n",
                   ";a{'foo'}a\n:b{=bar=}b")
    # one liner
    assert_convert("<dl>\n<dt><strong>foo</strong></dt>\n" +
                   "<dd><del>bar</del></dd>\n</dl>\n",
                   ";{''foo''};:{=bar=}")
  end

  def test_definition_with_block
    # normal
    assert_convert("<dl>\n<dt>a</dt>\n<dd><p>foo</p>\n<p>bar</p>\n</dd>\n</dl>\n",
                   ";a\n:(((\nfoo\n\nbar\n)))")
    # one liner
    assert_convert("<dl>\n<dt>a</dt>\n<dd><p>foo</p>\n<p>bar</p>\n</dd>\n</dl>\n",
                   ";a;:(((\nfoo\n\nbar\n)))")
    # nesting
    assert_convert(%Q|<dl>\n<dt>a</dt>\n| +
                   %Q|<dd><dl>\n<dt>b</dt>\n<dd><p>c</p>\n</dd>\n</dl>\n</dd>\n| +
                   %Q|</dl>\n|,
                   ";a\n:(((\n;b\n:(((\nc\n)))\n)))")
    assert_convert(%Q|<dl>\n<dt>a</dt>\n| +
                   %Q|<dd><blockquote>\n<p>foo\nbar</p>\n</blockquote>\n</dd>\n| +
                   %Q|</dl>\n|,
                   ";a\n:(((\n<<<b\nfoo\nbar\n>>>\n)))")
    assert_convert(%Q|<dl>\n<dt>a</dt>\n| +
                   %Q|<dd><blockquote>\n<p>foo</p>\n| +
                   %Q|<dl>\n<dt>bar</dt>\n<dd><p>baz</p>\n</dd>\n</dl>\n| +
                   %Q|</blockquote>\n</dd>\n| +
                   %Q|</dl>\n|,
                   ";a\n:(((\n<<<b\nfoo\n;bar;:(((\nbaz\n)))\n>>>\n)))")
    # backtracking
    assert_convert("<dl>\n<dt>a</dt>\n<dd>(((</dd>\n</dl>\n<p>foo</p>\n<p>bar</p>\n",
                   ";a\n:(((\nfoo\n\nbar\n")
    assert_convert(%Q|<dl>\n<dt>a</dt>\n<dd>(((</dd>\n</dl>\n| +
                   %Q|<p>foo</p>\n| +
                   %Q|<dl>\n<dt>bar</dt>\n<dd><p>baz</p>\n</dd>\n</dl>\n|,
                   ";a\n:(((\nfoo\n;bar;:(((\nbaz\n)))")
    assert_convert(%Q|<dl>\n<dt>a</dt>\n<dd>(((<br />foo</dd>\n| +
                   %Q|<dt>bar</dt>\n<dd><p>baz</p>\n</dd>\n</dl>\n|,
                   ";a\n:(((\n foo\n;bar;:(((\nbaz\n)))")

    # block elememts in dt is not allowed
    assert_convert("<dl>\n<dt>(((</dt>\n</dl>\n<p>foo\n)))</p>\n",
                   ";(((\nfoo\n)))")
  end

  def test_table
    # normal
    assert_convert(%Q|<table>\n<tr><td>a</td><td>b</td></tr>\n</table>\n|,
                   "||a||b")
    # empty item
    assert_convert(%Q|<table>\n<tr><td>a</td><td></td><td>b</td><td></td></tr>\n</table>\n|,
                   "||a||||b||")
    assert_convert(%Q|<table>\n<tr><td>a</td><td>b</td><td>c</td></tr>\n| +
                   %Q|<tr><td></td><td></td><td></td></tr>\n| +
                   %Q|<tr><td>d</td><td>e</td><td>f</td></tr>\n</table>\n|,
                   "||a||b||c\n||||||\n||d||e||f")
    # th
    assert_convert(%Q|<table>\n<tr><th>a</th><td>b</td></tr>\n</table>\n|,
                   "||!a||b")
    # modifier
    assert_convert(%Q|<table>\n<tr><td><em>foo</em></td><td>b<del>a</del>r</td></tr>\n</table>\n|,
                   "||{'foo'}||b{=a=}r")
    # link
    assert_convert(%Q|<table>\n<tr><td><a href=\"http://hikiwiki.org/\">Hiki</a></td></tr>\n</table>\n|,
                   "||[[Hiki|http://hikiwiki.org/]]")

    # rowspan/colspan
    assert_convert(%Q|<table>\n<tr><td colspan=\"2\">1</td><td rowspan=\"2\">2</td></tr>\n| +
                   %Q|<tr><td rowspan=\"3\"></td><td>4</td></tr>\n| +
                   %Q|<tr><td colspan=\"2\"></td></tr>\n</table>\n|,
                   "||>1||^2\n||^^||4\n||>")
    # breakline is not allowed in table
    assert_convert(%Q|<table>\n<tr><td>a</td></tr>\n</table>\n<p>b</p>\n|,
                   "||a\n b")
  end

  def test_table_with_link
    # normal
    assert_convert(%Q|<table>\n<tr>| +
                   %Q|<td><a href=\"http://hikiwiki.org/\">Hiki</a></td>| +
                   %Q|<td>foo</td></tr>\n</table>\n|,
                   %Q!||[[Hiki|http://hikiwiki.org/]]||foo!)
  end

  def test_table_with_attr
    # normal
    assert_convert(%Q|<table class="t_cls" title="t_title">\n| +
                   %Q|<tr class="tr_cls" title="tr_title">| +
                   %Q|<td class="td_cls" title="td_title">a</td><td>b</td></tr>\n</table>\n|,
                   %Q![ t_cls , "t_title" ]\n[ tr_cls , "tr_title" ]||[ td_cls , "td_title" ]a||b!)
    # enable_id
    assert_convert(%Q|<table id="t_id" class="t_cls" title="t_title">\n| +
                   %Q|<tr id="tr_id" class="tr_cls" title="tr_title">| +
                   %Q|<td id="td_id" class="td_cls" title="td_title">a</td><td>b</td></tr>\n</table>\n|,
                   %Q![ t_id , t_cls , "t_title" ]\n[ tr_id , tr_cls , "tr_title" ]||[ td_id , td_cls , "td_title" ]a||b!,
                   { :enable_id => true })

    # malformed tr attribute will be shown.
    assert_convert(%Q|<table class="t_cls" title="t_title">\n| +
                   %Q|<tr><td>[ ;tr_cls , "tr_title" ]</td>| +
                   %Q|<td class="td_cls" title="td_title">a</td><td>b</td></tr>\n</table>\n|,
                   %Q![ t_cls , "t_title" ]\n[ ;tr_cls , "tr_title" ]||[ td_cls , "td_title" ]a||b!)

    # not attribute
    assert_convert(%Q|<table>\n| +
                   %Q|<tr>| +
                   %Q|<td>[ td_cls , "td_title" ]a</td><td>b</td></tr>\n</table>\n|,
                   %Q!|| [ td_cls , "td_title" ]a||b!)
  end

  def test_table_with_modifier
    # normal
    assert_convert("<table>\n<tr><td><em>foo</em></td><td><del>bar</del></td><td>baz</td></tr>\n</table>\n",
                   "||{'foo'}||{=bar=}||baz")
    assert_convert("<table>\n<tr><td>a<em>foo</em>a</td><td>b<del>bar</del>b</td><td>baz</td></tr>\n</table>\n",
                   "||a{'foo'}a||b{=bar=}b||baz")
  end

  def test_table_with_block
    # normal
    assert_convert(%Q|<table>\n<tr><td><p>foo</p>\n</td><td>b</td></tr>\n</table>\n|,
                   "||(((||b\nfoo\n)))")
    # block elements
    assert_convert(%Q|<table>\n| +
                   %Q|<tr><td><p>foo</p>\n| +
                   %Q|<blockquote>\n<p>bar</p>\n</blockquote>\n</td><td>b</td></tr>\n| +
                   %Q|</table>\n|,
                   "||(((||b\nfoo\n<<<b\nbar\n>>>\n)))")
    # multi cell
    assert_convert(%Q|<table>\n| +
                   %Q|<tr><td><p>foo</p>\n</td><td>b</td>| +
                   %Q|<td><p>bar</p>\n</td><td>d</td></tr>\n</table>\n|,
                   "||(((||b||(((||d\nfoo\n)))\nbar\n)))")
    # multi line
    assert_convert(%Q|<table>\n| +
                   %Q|<tr><td><p>foo</p>\n</td><td>b</td></tr>\n| +
                   %Q|<tr><td>c</td><td><p>bar</p>\n</td><td>d</td></tr>\n</table>\n|,
                   "||(((||b\n||c||(((||d\nfoo\n)))\nbar\n)))")

    # th
    assert_convert(%Q|<table>\n<tr><th><p>foo</p>\n</th><td>b</td></tr>\n</table>\n|,
                   "||!(((||b\nfoo\n)))")
    # comment
    assert_convert(%Q|<table>\n| +
                   %Q|<tr><td><blockquote>\n<p>foo</p>\n</blockquote>\n</td>| +
                   %Q|<td>b</td></tr>\n</table>\n|,
                   "||(((||b\n// (1,1)\n<<<b\nfoo\n>>>\n)))")

    # nesting
    ## needs blank line to avoid ambiguity
    assert_convert(%Q|<table>\n| +
                   %Q|<tr><td><table>\n<tr><td>a</td></tr>\n</table>\n</td>| +
                   %Q|<td>b</td></tr>\n</table>\n|,
                   %Q!||(((||b\n\n||a\n)))!)
    ## If you don't, It's the feature ;).
    assert_convert(%Q|<table>\n| +
                   %Q|<tr><td></td><td>b</td></tr>\n| +
                   %Q|<tr><td>a</td></tr>\n| +
                   %Q|</table>\n|,
                   %Q!||(((||b\n||a\n)))!)
    ## list(with block)
    assert_convert(%Q|<table>\n| +
                   %Q|<tr><td><p>foo</p>\n| +
                   %Q|<ul>\n<li><p>bar</p>\n</li>\n</ul>\n</td>| +
                   %Q|<td>b</td></tr>\n</table>\n|,
                   "||(((||b\nfoo\n*(((\nbar\n)))\n)))")

    # not block
    assert_convert(%Q|<table>\n| +
                   %Q|<tr><td>&lt;&lt;&lt;</td><td>b</td></tr>\n| +
                   %Q|</table>\n| +
                   %Q|<p>foo</p>\n|,
                   "||<<<||b\nfoo\n")

    # backtracking
    assert_convert(%Q|<table>\n| +
                   %Q|<tr><td>(((</td><td>b</td></tr>\n| +
                   %Q|</table>\n| +
                   %Q|<p>foo</p>\n|,
                   "||(((||b\nfoo\n")
    assert_convert(%Q|<table>\n| +
                   %Q|<tr><td><p>foo</p>\n</td><td>(((</td><td>a</td></tr>\n| +
                   %Q|</table>\n|,
                   "||(((||(((||a\nfoo\n)))")
  end

  def test_modifier
    # color
    assert_convert(%Q|<p><span style="color: red;">foo</span></p>\n|,
                   "{~red:foo~}")
    assert_convert(%Q|<p><font color="red">foo</font></p>\n|,
                   "{~red:foo~}", { :amazon_dtp_mode => true })
    assert_convert(%Q|<p><span style="color: red;">:foo:bar:</span></p>\n|,
                   "{~red::foo:bar:~}")
    # em
    assert_convert("<p><em>foo</em></p>\n",
                   "{'foo'}")
    assert_convert("<p><em>fo'o</em></p>\n",
                   "{'fo'o'}")
    assert_convert("<p><em>fo}o</em></p>\n",
                   "{'fo}o'}")
    # strong
    assert_convert("<p><strong>foo</strong></p>\n",
                   "{''foo''}")
    assert_convert("<p><strong>fo'o</strong></p>\n",
                   "{''fo'o''}")
    assert_convert("<p><strong>fo''o</strong></p>\n",
                   "{''fo''o''}")
    assert_convert("<p><strong>fo}o</strong></p>\n",
                   "{''fo}o''}")
    # underline
    assert_convert("<p><u>foo</u></p>\n",
                   "{_foo_}")
    assert_convert("<p><u>fo_o</u></p>\n",
                   "{_fo_o_}")
    assert_convert("<p><u>fo}o</u></p>\n",
                   "{_fo}o_}")
    # itaric
    assert_convert("<p><i>foo</i></p>\n",
                   "{/foo/}")
    assert_convert("<p><i>fo/o</i></p>\n",
                   "{/fo/o/}")
    assert_convert("<p><i>fo}o</i></p>\n",
                   "{/fo}o/}")
    # delete
    assert_convert("<p><del>foo</del></p>\n",
                   "{=foo=}")
    assert_convert("<p><del>fo=o</del></p>\n",
                   "{=fo=o=}")
    assert_convert("<p><del>fo}o</del></p>\n",
                   "{=fo}o=}")
    # big
    assert_convert("<p><big>foo</big></p>\n",
                   "{+foo+}")
    assert_convert("<p><big>fo+o</big></p>\n",
                   "{+fo+o+}")
    assert_convert("<p><big>fo}o</big></p>\n",
                   "{+fo}o+}")
    # small
    assert_convert("<p><small>foo</small></p>\n",
                   "{-foo-}")
    assert_convert("<p><small>fo-o</small></p>\n",
                   "{-fo-o-}")
    assert_convert("<p><small>fo}o</small></p>\n",
                   "{-fo}o-}")
    # sup
    assert_convert("<p><sup>foo</sup></p>\n",
                   "{^^foo^^}")
    assert_convert("<p><sup>fo^o</sup></p>\n",
                   "{^^fo^o^^}")
    assert_convert("<p><sup>fo^^o</sup></p>\n",
                   "{^^fo^^o^^}")
    assert_convert("<p><sup>fo}o</sup></p>\n",
                   "{^^fo}o^^}")
    # sub
    assert_convert("<p><sub>foo</sub></p>\n",
                   "{__foo__}")
    assert_convert("<p><sub>fo_o</sub></p>\n",
                   "{__fo_o__}")
    assert_convert("<p><sub>fo__o</sub></p>\n",
                   "{__fo__o__}")
    assert_convert("<p><sub>fo}o</sub></p>\n",
                   "{__fo}o__}")
    # teletype
    assert_convert("<p><tt>foo</tt></p>\n",
                   "{`foo`}")
    assert_convert("<p><tt>fo`o</tt></p>\n",
                   "{`fo`o`}")
    assert_convert("<p><tt>fo}o</tt></p>\n",
                   "{`fo}o`}")
    # cite
    assert_convert("<p><cite>foo</cite></p>\n",
                   "{@foo@}")
    assert_convert("<p><cite>fo@o</cite></p>\n",
                   "{@fo@o@}")
    assert_convert("<p><cite>fo}o</cite></p>\n",
                   "{@fo}o@}")
    # asis
    assert_convert("<p>foo</p>\n",
                   "{!foo!}")
    assert_convert("<p>fo!o</p>\n",
                   "{!fo!o!}")
    assert_convert("<p>fo}o</p>\n",
                   "{!fo}o!}")
    assert_convert("<p>{'foo'}</p>\n",
                   "{!{'foo'}!}")
    # span
    assert_convert("<p><span>foo</span></p>\n",
                   %Q|{"foo"}|)
    assert_convert(%Q|<p><span>fo"o</span></p>\n|,
                   %Q|{"fo"o"}|)
    assert_convert("<p><span>fo}o</span></p>\n",
                   %Q|{"fo}o"}|)
    # math
    assert_convert(%Q|<p><span class="math">| +
                   %Q|<span class="plugin">{{mtex 'foo'}}</span></span>| +
                   %Q|</p>\n|,
                   "{$foo$}")
    assert_convert(%Q|<p><span class="math">| +
                   %Q|<span class="plugin">{{mtex 'fo$o'}}</span></span>| +
                   %Q|</p>\n|,
                   "{$fo$o$}")
    assert_convert(%Q|<p><span class="math">| +
                   %Q|<span class="plugin">{{mtex 'fo}o'}}</span></span>| +
                   %Q|</p>\n|,
                   "{$fo}o$}")
    # multi
    assert_convert("<p><strong>foo</strong> and <strong>bar</strong></p>\n",
                   "{''foo''} and {''bar''}")
    assert_convert("<p><em>foo</em> and <strong>bar</strong></p>\n",
                   "{'foo'} and {''bar''}")
    # cross
    assert_convert("<p><em>foo{=bar</em>baz=}</p>\n",
                   "{'foo{=bar'}baz=}")
    assert_convert("<p><tt>foo{=bar</tt>baz=}</p>\n",
                   "{`foo{=bar`}baz=}")
    # security
    assert_convert("<p>&lt;s&gt;</p>\n",
                   "{!<s>!}")
  end

  def test_modifier_with_attr
    # normal
    assert_convert(%Q!<p><strong class="cls" title="title">bar</strong></p>\n!,
                   %Q|{''[ cls , "title" ]bar''}|)
    assert_convert(%Q!<p><strong title="title">bar</strong></p>\n!,
                   %Q|{''["title"]bar''}|)
    # enable_id
    assert_convert(%Q!<p><strong id="id" class="cls" title="title">bar</strong></p>\n!,
                   %Q|{''[ id , cls , "title" ]bar''}|,
                   { :enable_id => true })

    # not attribute
    assert_convert(%Q!<p><strong>[ cls , "title" ]bar</strong></p>\n!,
                   %Q|{'' [ cls , "title" ]bar''}|)

    # math-tag appends "math" in class
    assert_convert(%Q|<p><span class="math cls">| +
                   %Q|<span class="plugin">{{mtex 'foo'}}</span></span>| +
                   %Q|</p>\n|,
                   "{$[cls]foo$}")
    assert_convert(%Q|<p><span class="math" title="title">| +
                   %Q|<span class="plugin">{{mtex 'foo'}}</span></span>| +
                   %Q|</p>\n|,
                   %Q|{$["title"]foo$}|)
    assert_convert(%Q|<p><span class="math cls" title="title">| +
                   %Q|<span class="plugin">{{mtex 'foo'}}</span></span>| +
                   %Q|</p>\n|,
                   %Q|{$[ cls , "title" ]foo$}|)

    # color
    assert_convert(%Q|<p><span style="color: red;" class="cls">text</span></p>\n|,
                   "{~[cls]red:text~}")
    assert_convert(%Q|<p><span style="color: red;" title="title">text</span></p>\n|,
                   %Q|{~["title"]red:text~}|)
    assert_convert(%Q|<p><span style="color: red;" class="cls" title="title">text</span></p>\n|,
                   %Q|{~[ cls, "title" ]red:text~}|)

    assert_convert(%Q|<p><font color="red" class="cls">text</font></p>\n|,
                   "{~[cls]red:text~}", { :amazon_dtp_mode => true })
    assert_convert(%Q|<p><font color="red" title="title">text</font></p>\n|,
                   %Q|{~["title"]red:text~}|, { :amazon_dtp_mode => true })

    # not attribute
    assert_convert(%Q!<p><strong>[ cls , \"title\" ]bar</strong></p>\n!,
                   %Q|{'' [ cls , "title" ]bar''}|)

  end

  def test_nested_modifier
    assert_convert("<p><em><del>foo</del></em></p>\n",
                   "{'{=foo=}'}")
    assert_convert("<p><del><em>foo</em></del></p>\n",
                   "{={'foo'}=}")
  end

  def test_modifier_and_link
    assert_convert("<p><a href=\"http://hikiwiki.org/\"><strong>Hiki</strong></a></p>\n",
                   "[[{''Hiki''}|http://hikiwiki.org/]]")
    assert_convert("<p><strong><a href=\"http://hikiwiki.org/\">Hiki</a></strong></p>\n",
                   "{''[[Hiki|http://hikiwiki.org/]]''}")
  end

  def test_div
    # normal
    assert_convert(%Q|<div>\n<p>bar</p>\n</div>\n|,
                   "<<<div\nbar\n>>>")
    assert_convert(%Q|<div>\n<p>bar</p>\n</div>\n|,
                   "<<<d\nbar\n>>>")
    assert_convert(%Q|<div>\n<p>bar</p>\n</div>\n|,
                   "<<< div\nbar\n>>>")
    assert_convert(%Q|<div>\n<p>bar</p>\n</div>\n|,
                   "<<< d\nbar\n>>>")
    assert_convert(%Q|<div>\n<p>&lt;&lt;&lt;&lt;\nbar\n&gt;&gt;&gt;&gt;</p>\n</div>\n|,
                   "<<<d\n<<<<\nbar\n>>>>\n>>>")
    # breakline
    assert_convert("<div>\n<p>foo<br />\nfuga</p>\n</div>\n",
                   %Q|<<<d\nfoo\n fuga\n>>>|)
    # multi paragraph
    assert_convert("<div>\n<p>foo\nbar</p>\n<p>baz</p>\n</div>\n",
                   %Q|<<<d\nfoo\nbar\n\nbaz\n>>>|)
    # header
    assert_convert("<div>\n<h1>foo</h1>\n</div>\n",
                   %Q|<<<d\n! foo\n>>>|)
    # thematic break
    assert_convert("<div>\n<hr />\n</div>\n",
                   %Q|<<<d\n----\n>>>|)
    # modifier
    assert_convert("<div>\n<p>a<em>foo</em>b</p>\n</div>\n",
                   %Q|<<<d\na{'foo'}b\n>>>|)
    # list
    assert_convert("<div>\n<ul>\n<li>foo</li>\n</ul>\n</div>\n",
                   %Q|<<<d\n* foo\n>>>|)
    # list with block
    assert_convert("<div>\n<ul>\n<li><p>foo<br />\nbar</p>\n</li>\n</ul>\n</div>\n",
                   %Q|<<<d\n*(((\nfoo\n bar\n)))\n>>>|)
    # list with block(allow blank)
    assert_convert("<div>\n<ul>\n<li><p>foo<br />\nbar</p>\n</li>\n</ul>\n</div>\n",
                   %Q|<<<d\n* (((\nfoo\n bar\n)))\n>>>|)
    # definition lists
    assert_convert("<div>\n<dl>\n<dt>foo</dt>\n<dd>bar</dd>\n</dl>\n</div>\n",
                   %Q|<<<d\n;foo\n:bar\n>>>|)
    # definition lists with block
    assert_convert("<div>\n<dl>\n<dt>foo</dt>\n<dd><p>bar</p>\n</dd>\n</dl>\n</div>\n",
                   %Q|<<<d\n;foo\n:(((\nbar\n)))\n>>>|)
    # table
    assert_convert("<div>\n<table>\n<tr><td>foo</td></tr>\n</table>\n</div>\n",
                   %Q!<<<d\n||foo\n>>>!)
    # table with block
    assert_convert("<div>\n<table>\n<tr><td><p>foo</p>\n</td></tr>\n</table>\n</div>\n",
                   %Q!<<<d\n||(((\nfoo\n)))\n>>>!)
    # block plugin
    assert_convert(%Q|<div class="foo">\n| +
                   %Q!<div class="plugin">{{'test'}}</div>\n! +
                   %Q!</div>\n!,
                   %Q!<<<[foo]\n{{'test'}}\n>>>!)
    # inline plugin
    assert_convert(%Q|<div class="foo">\n| +
                   %Q!<p>a<span class="plugin">{{'test'}}</span>a</p>\n! +
                   %Q!</div>\n!,
                   %Q!<<<[foo]\na{{'test'}}a\n>>>!)

    # nesting
    ## div
    assert_convert("<div>\n<div>\n<p>foo</p>\n</div>\n</div>\n",
                   %Q!<<<d\n<<<d\nfoo\n>>>\n>>>!)
    ## blockquote
    assert_convert("<div>\n<blockquote>\n<p>foo</p>\n</blockquote>\n</div>\n",
                   %Q!<<<d\n<<<b\nfoo\n>>>\n>>>!)
    ## left
    assert_convert(%Q!<div>\n<div style="text-align:left;">\n<p>foo</p>\n</div>\n</div>\n!,
                   %Q!<<<d\n<<<l\nfoo\n>>>\n>>>!)
    ## center
    assert_convert(%Q!<div>\n<div style="text-align:center;">\n<p>foo</p>\n</div>\n</div>\n!,
                   %Q!<<<d\n<<<c\nfoo\n>>>\n>>>!)
    ## right
    assert_convert(%Q!<div>\n<div style="text-align:right;">\n<p>foo</p>\n</div>\n</div>\n!,
                   %Q!<<<d\n<<<r\nfoo\n>>>\n>>>!)
    ## asis
    assert_convert("<div>\n<p>foo</p>\n</div>\n",
                   %Q!<<<d\n<<<a\nfoo\n>>>\n>>>!)
    ## pre
    assert_convert("<div>\n<pre>foo</pre>\n</div>\n",
                   %Q!<<<d\n<<<p\nfoo\n>>>\n>>>!)
    ## pre_asis
    assert_convert("<div>\n<pre>foo</pre>\n</div>\n",
                   %Q!<<<d\n<<<pa\nfoo\n>>>\n>>>!)

    # not div
    assert_convert(%Q|<p>&lt;&lt;&lt;div a\nbar\n&gt;&gt;&gt;</p>\n|,
                   "<<<div a\nbar\n>>>")
    assert_convert(%Q|<p>&lt;&lt;&lt;d a\nbar\n&gt;&gt;&gt;</p>\n|,
                   "<<<d a\nbar\n>>>")
    # backtracking
    assert_convert("<p>&lt;&lt;&lt;d\nfoo</p>\n",
                   %Q!<<<d\nfoo\n!)
    assert_convert("<p>&lt;&lt;&lt;d<br />\nfoo</p>\n",
                   %Q!<<<d\n foo\n!)
    assert_convert("<p>&lt;&lt;&lt;d</p>\n<div>\n<p>foo</p>\n</div>\n",
                   %Q!<<<d\n<<<d\nfoo\n>>>!)
  end

  def test_div_with_attr
    assert_convert(%Q|<div class="cls">\n<p>bar</p>\n</div>\n|,
                   %Q!<<<div[cls]\nbar\n>>>!)
    assert_convert(%Q|<div title="title">\n<p>bar</p>\n</div>\n|,
                   %Q!<<<div["title"]\nbar\n>>>!)
    assert_convert(%Q|<div title="title">\n<p>bar</p>\n</div>\n|,
                   %Q!<<<div[,"title"]\nbar\n>>>!)
    assert_convert(%Q|<div class="cls" title="title">\n<p>bar</p>\n</div>\n|,
                   %Q!<<<div[cls,"title"]\nbar\n>>>!)
    assert_convert(%Q|<div class="cls" title="title">\n<p>bar</p>\n</div>\n|,
                   %Q!<<<div[ cls , "title" ]\nbar\n>>>!)
    # enable_id
    assert_convert(%Q|<div id="id" class="cls" title="title">\n<p>bar</p>\n</div>\n|,
                   %Q!<<<div[ id , cls , "title"]\nbar\n>>>!,
                   { :enable_id => true })
    # abbreviation
    assert_convert(%Q|<div class="cls" title="title">\n<p>bar</p>\n</div>\n|,
                   %Q!<<<[ cls , "title" ]\nbar\n>>>!)

    # not attribute
    assert_convert(%Q|<p>&lt;&lt;&lt;div\\[foo,\"bar,baz\"]\ntext\n&gt;&gt;&gt;</p>\n|,
                   %Q|<<<div\\[foo,"bar,baz"]\ntext\n>>>|)
    assert_convert(%Q|<p>&lt;&lt;&lt;div [ cls , \"title\" ]\nbar\n&gt;&gt;&gt;</p>\n|,
                   %Q!<<<div [ cls , "title" ]\nbar\n>>>!)
  end

  def test_blockquote
    # normal
    assert_convert("<blockquote>\n<p>foo</p>\n</blockquote>\n",
                   %Q|<<<blockquote\nfoo\n>>>|)
    assert_convert("<blockquote>\n<p>foo</p>\n</blockquote>\n",
                   %Q|<<<b\nfoo\n>>>|)
    assert_convert("<blockquote>\n<p>foo</p>\n</blockquote>\n",
                   %Q|<<< blockquote\nfoo\n>>>|)
    assert_convert("<blockquote>\n<p>foo</p>\n</blockquote>\n",
                   %Q|<<< b\nfoo\n>>>|)

    # breakline
    assert_convert("<blockquote>\n<p>foo<br />\nfuga</p>\n</blockquote>\n",
                   %Q|<<<b\nfoo\n fuga\n>>>|)
    # multi paragraph
    assert_convert("<blockquote>\n<p>foo\nbar</p>\n<p>baz</p>\n</blockquote>\n",
                   %Q|<<<b\nfoo\nbar\n\nbaz\n>>>|)
    # header
    assert_convert("<blockquote>\n<h1>foo</h1>\n</blockquote>\n",
                   %Q|<<<b\n! foo\n>>>|)
    # thematic break
    assert_convert("<blockquote>\n<hr />\n</blockquote>\n",
                   %Q|<<<b\n----\n>>>|)
    # modifier
    assert_convert("<blockquote>\n<p>a<em>foo</em>b</p>\n</blockquote>\n",
                   %Q|<<<b\na{'foo'}b\n>>>|)
    # list
    assert_convert("<blockquote>\n<ul>\n<li>foo</li>\n</ul>\n</blockquote>\n",
                   %Q|<<<b\n* foo\n>>>|)
    # list with block
    assert_convert("<blockquote>\n<ul>\n<li><p>foo<br />\nbar</p>\n</li>\n</ul>\n</blockquote>\n",
                   %Q|<<<b\n*(((\nfoo\n bar\n)))\n>>>|)
    # list with block(allow blank)
    assert_convert("<blockquote>\n<ul>\n<li><p>foo<br />\nbar</p>\n</li>\n</ul>\n</blockquote>\n",
                   %Q|<<<b\n* (((\nfoo\n bar\n)))\n>>>|)
    # definition lists
    assert_convert("<blockquote>\n<dl>\n<dt>foo</dt>\n<dd>bar</dd>\n</dl>\n</blockquote>\n",
                   %Q|<<<b\n;foo\n:bar\n>>>|)
    # definition lists with block
    assert_convert("<blockquote>\n<dl>\n<dt>foo</dt>\n<dd><p>bar</p>\n</dd>\n</dl>\n</blockquote>\n",
                   %Q|<<<b\n;foo\n:(((\nbar\n)))\n>>>|)
    # table
    assert_convert("<blockquote>\n<table>\n<tr><td>foo</td></tr>\n</table>\n</blockquote>\n",
                   %Q!<<<b\n||foo\n>>>!)
    # table with block
    assert_convert("<blockquote>\n<table>\n<tr><td><p>foo</p>\n</td></tr>\n</table>\n</blockquote>\n",
                   %Q!<<<b\n||(((\nfoo\n)))\n>>>!)
    # block plugin
    assert_convert(%Q!<blockquote>\n<div class=\"plugin\">{{'test'}}</div>\n</blockquote>\n!,
                   %Q!<<<b\n{{'test'}}\n>>>!)
    # inline plugin
    assert_convert(%Q!<blockquote>\n<p>a<span class=\"plugin\">{{'test'}}</span>a</p>\n</blockquote>\n!,
                   %Q!<<<b\na{{'test'}}a\n>>>!)

    # nesting
    ## div
    assert_convert("<blockquote>\n<div>\n<p>foo</p>\n</div>\n</blockquote>\n",
                   %Q!<<<b\n<<<d\nfoo\n>>>\n>>>!)
    ## blockquote
    assert_convert("<blockquote>\n<blockquote>\n<p>foo</p>\n</blockquote>\n</blockquote>\n",
                   %Q!<<<b\n<<<b\nfoo\n>>>\n>>>!)
    ## left
    assert_convert(%Q!<blockquote>\n<div style="text-align:left;">\n<p>foo</p>\n</div>\n</blockquote>\n!,
                   %Q!<<<b\n<<<l\nfoo\n>>>\n>>>!)
    ## center
    assert_convert(%Q!<blockquote>\n<div style="text-align:center;">\n<p>foo</p>\n</div>\n</blockquote>\n!,
                   %Q!<<<b\n<<<c\nfoo\n>>>\n>>>!)
    ## right
    assert_convert(%Q!<blockquote>\n<div style="text-align:right;">\n<p>foo</p>\n</div>\n</blockquote>\n!,
                   %Q!<<<b\n<<<r\nfoo\n>>>\n>>>!)
    ## asis
    assert_convert("<blockquote>\n<p>foo</p>\n</blockquote>\n",
                   %Q!<<<b\n<<<a\nfoo\n>>>\n>>>!)
    ## pre
    assert_convert("<blockquote>\n<pre>foo</pre>\n</blockquote>\n",
                   %Q!<<<b\n<<<p\nfoo\n>>>\n>>>!)
    ## pre_asis
    assert_convert("<blockquote>\n<pre>foo</pre>\n</blockquote>\n",
                   %Q!<<<b\n<<<pa\nfoo\n>>>\n>>>!)

    # not blockquote
    assert_convert("<p>&lt;&lt;&lt;blockquote a\nfoo\n&gt;&gt;&gt;</p>\n",
                   %Q|<<<blockquote a\nfoo\n>>>|)
    assert_convert("<p>&lt;&lt;&lt;b a\nfoo\n&gt;&gt;&gt;</p>\n",
                   %Q|<<<b a\nfoo\n>>>|)

    # backtracking
    assert_convert("<p>&lt;&lt;&lt;b\nfoo</p>\n",
                   %Q!<<<b\nfoo\n!)
    assert_convert("<p>&lt;&lt;&lt;b<br />\nfoo</p>\n",
                   %Q!<<<b\n foo\n!)
    assert_convert("<p>&lt;&lt;&lt;b</p>\n<blockquote>\n<p>foo</p>\n</blockquote>\n",
                   %Q!<<<b\n<<<b\nfoo\n>>>!)
  end

  def test_blockquote_with_attr
    # normal
    assert_convert(%Q|<blockquote class="cls" title="title">\n<p>foo</p>\n</blockquote>\n|,
                   %Q|<<<blockquote[ cls , "title" ]\nfoo\n>>>|)
#    assert_convert(%Q|<blockquote class="cls" title="title">\n<p>foo</p>\n</blockquote>\n|,
#                   %Q|<<<blockquote [ cls , "title" ]\nfoo\n>>>|)

    assert_convert(%Q|<blockquote class="cls" title="title">\n<p>foo</p>\n</blockquote>\n|,
                   %Q|<<<b[ cls , "title" ]\nfoo\n>>>|)
    #enable_id
    assert_convert(%Q|<blockquote id="id" class="cls" title="title">\n<p>foo</p>\n</blockquote>\n|,
                   %Q|<<<blockquote[ id , cls , "title" ]\nfoo\n>>>|,
                   { :enable_id => true })

    assert_convert(%Q|<blockquote id="id" class="cls" title="title">\n<p>foo</p>\n</blockquote>\n|,
                   %Q|<<<b[ id , cls , "title" ]\nfoo\n>>>|,
                   { :enable_id => true })
  end

  def test_center
    # normal
    assert_convert(%Q|<div style="text-align:center;">\n<p>foo</p>\n</div>\n|,
                   "<<<center\nfoo\n>>>")
    assert_convert(%Q|<div style="text-align:center;">\n<p>foo</p>\n</div>\n|,
                   "<<< center\nfoo\n>>>")
    assert_convert(%Q|<div style="text-align:center;">\n<p>foo</p>\n</div>\n|,
                   "<<<c\nfoo\n>>>")
    assert_convert(%Q|<div style="text-align:center;">\n<p>foo</p>\n</div>\n|,
                   "<<< c\nfoo\n>>>")
    ## amazon
    assert_convert(%Q|<div align="center">\n<p>foo</p>\n</div>\n|,
                   "<<<center\nfoo\n>>>", { :amazon_dtp_mode => true })
    assert_convert(%Q|<div align="center">\n<p>foo</p>\n</div>\n|,
                   "<<<c\nfoo\n>>>", { :amazon_dtp_mode => true })

    # breakline
    assert_convert(%Q!<div style="text-align:center;">\n<p>foo<br />\nfuga</p>\n</div>\n!,
                   %Q|<<<c\nfoo\n fuga\n>>>|)
    # multi paragraph
    assert_convert(%Q!<div style="text-align:center;">\n<p>foo\nbar</p>\n<p>baz</p>\n</div>\n!,
                   %Q|<<<c\nfoo\nbar\n\nbaz\n>>>|)
    # header
    assert_convert(%Q!<div style="text-align:center;">\n<h1>foo</h1>\n</div>\n!,
                   %Q|<<<c\n! foo\n>>>|)
    # thematic break
    assert_convert(%Q!<div style="text-align:center;">\n<hr />\n</div>\n!,
                   %Q|<<<c\n----\n>>>|)
    # modifier
    assert_convert(%Q!<div style="text-align:center;">\n<p>a<em>foo</em>b</p>\n</div>\n!,
                   %Q|<<<c\na{'foo'}b\n>>>|)
    # list
    assert_convert(%Q!<div style="text-align:center;">\n<ul>\n<li>foo</li>\n</ul>\n</div>\n!,
                   %Q|<<<c\n* foo\n>>>|)
    # list with block
    assert_convert(%Q!<div style="text-align:center;">\n<ul>\n<li><p>foo<br />\nbar</p>\n</li>\n</ul>\n</div>\n!,
                   %Q|<<<c\n*(((\nfoo\n bar\n)))\n>>>|)
    # list with block(allow blank)
    assert_convert(%Q!<div style="text-align:center;">\n<ul>\n<li><p>foo<br />\nbar</p>\n</li>\n</ul>\n</div>\n!,
                   %Q|<<<c\n* (((\nfoo\n bar\n)))\n>>>|)
    # definition lists
    assert_convert(%Q!<div style="text-align:center;">\n<dl>\n<dt>foo</dt>\n<dd>bar</dd>\n</dl>\n</div>\n!,
                   %Q|<<<c\n;foo\n:bar\n>>>|)
    # definition lists with block
    assert_convert(%Q!<div style="text-align:center;">\n<dl>\n<dt>foo</dt>\n<dd><p>bar</p>\n</dd>\n</dl>\n</div>\n!,
                   %Q|<<<c\n;foo\n:(((\nbar\n)))\n>>>|)
    # table
    assert_convert(%Q!<div style="text-align:center;">\n<table>\n<tr><td>foo</td></tr>\n</table>\n</div>\n!,
                   %Q!<<<c\n||foo\n>>>!)
    # table with block
    assert_convert(%Q!<div style="text-align:center;">\n<table>\n<tr><td><p>foo</p>\n</td></tr>\n</table>\n</div>\n!,
                   %Q!<<<c\n||(((\nfoo\n)))\n>>>!)
    # block plugin
    assert_convert(%Q!<div style="text-align:center;">\n<div class=\"plugin\">{{'test'}}</div>\n</div>\n!,
                   %Q!<<<c\n{{'test'}}\n>>>!)
    # inline plugin
    assert_convert(%Q!<div style="text-align:center;">\n<p>a<span class=\"plugin\">{{'test'}}</span>a</p>\n</div>\n!,
                   %Q!<<<c\na{{'test'}}a\n>>>!)

    # nesting
    ## div
    assert_convert(%Q!<div style="text-align:center;">\n<div>\n<p>foo</p>\n</div>\n</div>\n!,
                   %Q!<<<c\n<<<d\nfoo\n>>>\n>>>!)
    ## blockquote
    assert_convert(%Q!<div style="text-align:center;">\n<blockquote>\n<p>foo</p>\n</blockquote>\n</div>\n!,
                   %Q!<<<c\n<<<b\nfoo\n>>>\n>>>!)
    ## left
    assert_convert(%Q!<div style="text-align:center;">\n<div style="text-align:left;">\n<p>foo</p>\n</div>\n</div>\n!,
                   %Q!<<<c\n<<<l\nfoo\n>>>\n>>>!)
    ## center
    assert_convert(%Q!<div style="text-align:center;">\n<div style="text-align:center;">\n<p>foo</p>\n</div>\n</div>\n!,
                   %Q!<<<c\n<<<c\nfoo\n>>>\n>>>!)
    ## right
    assert_convert(%Q!<div style="text-align:center;">\n<div style="text-align:right;">\n<p>foo</p>\n</div>\n</div>\n!,
                   %Q!<<<c\n<<<r\nfoo\n>>>\n>>>!)
    ## asis
    assert_convert(%Q!<div style="text-align:center;">\n<p>foo</p>\n</div>\n!,
                   %Q!<<<c\n<<<a\nfoo\n>>>\n>>>!)
    ## pre
    assert_convert(%Q!<div style="text-align:center;">\n<pre>foo</pre>\n</div>\n!,
                   %Q!<<<c\n<<<p\nfoo\n>>>\n>>>!)
    ## pre_asis
    assert_convert(%Q!<div style="text-align:center;">\n<pre>foo</pre>\n</div>\n!,
                   %Q!<<<c\n<<<pa\nfoo\n>>>\n>>>!)

    # not blockquote
    assert_convert(%Q!<p>&lt;&lt;&lt;center a\nfoo\n&gt;&gt;&gt;</p>\n!,
                   %Q|<<<center a\nfoo\n>>>|)
    assert_convert(%Q!<p>&lt;&lt;&lt;c a\nfoo\n&gt;&gt;&gt;</p>\n!,
                   %Q|<<<c a\nfoo\n>>>|)

    # backtracking
    assert_convert(%Q!<p>&lt;&lt;&lt;c\nfoo</p>\n!,
                   %Q!<<<c\nfoo\n!)
    assert_convert(%Q!<p>&lt;&lt;&lt;c<br />\nfoo</p>\n!,
                   %Q!<<<c\n foo\n!)
    assert_convert(%Q!<p>&lt;&lt;&lt;c</p>\n<div style="text-align:center;">\n<p>foo</p>\n</div>\n!,
                   %Q!<<<c\n<<<c\nfoo\n>>>!)
  end

  def test_center_with_attr
    assert_convert(%Q|<div style="text-align:center;" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<<center[ cls , "title" ]\nfoo\n>>>!)
#    assert_convert(%Q|<div style="text-align:center;" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
#                   %Q!<<<center [ cls , "title" ]\nfoo\n>>>!)
    assert_convert(%Q|<div style="text-align:center;" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<<c[ cls , "title" ]\nfoo\n>>>!)
    assert_convert(%Q|<div style="text-align:center;" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<< c[ cls , "title" ]\nfoo\n>>>!)

    # amazon
    assert_convert(%Q|<div align="center" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<<center[ cls , "title" ]\nfoo\n>>>!, { :amazon_dtp_mode => true })

    # enable_id
    assert_convert(%Q|<div style="text-align:center;" id="id" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<<center[ id , cls , "title" ]\nfoo\n>>>!, { :enable_id => true })
    assert_convert(%Q|<div style="text-align:center;" id="id" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<<c[ id , cls , "title" ]\nfoo\n>>>!, { :enable_id => true })
  end

  def test_right
    # normal
    assert_convert(%Q|<div style="text-align:right;">\n<p>foo</p>\n</div>\n|,
                   "<<<right\nfoo\n>>>")
    assert_convert(%Q|<div style="text-align:right;">\n<p>foo</p>\n</div>\n|,
                   "<<<r\nfoo\n>>>")
    assert_convert(%Q|<div style="text-align:right;">\n<p>foo</p>\n</div>\n|,
                   "<<< right\nfoo\n>>>")
    assert_convert(%Q|<div style="text-align:right;">\n<p>foo</p>\n</div>\n|,
                   "<<< r\nfoo\n>>>")
    # amazon
    assert_convert(%Q|<div align="right">\n<p>foo</p>\n</div>\n|,
                   "<<<right\nfoo\n>>>", { :amazon_dtp_mode => true })
    assert_convert(%Q|<div align="right">\n<p>foo</p>\n</div>\n|,
                   "<<<r\nfoo\n>>>", { :amazon_dtp_mode => true })
    assert_convert(%Q|<div align="right">\n<p>foo</p>\n</div>\n|,
                   "<<< right\nfoo\n>>>", { :amazon_dtp_mode => true })
    assert_convert(%Q|<div align="right">\n<p>foo</p>\n</div>\n|,
                   "<<< r\nfoo\n>>>", { :amazon_dtp_mode => true })
  end

  def test_right_with_attr
    assert_convert(%Q|<div style="text-align:right;" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<<right[ cls , "title" ]\nfoo\n>>>!)
    assert_convert(%Q|<div style="text-align:right;" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<< right[ cls , "title" ]\nfoo\n>>>!)
    assert_convert(%Q|<div style="text-align:right;" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<<r[ cls , "title" ]\nfoo\n>>>!)
    assert_convert(%Q|<div style="text-align:right;" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<< r[ cls , "title" ]\nfoo\n>>>!)

    # amazon
    assert_convert(%Q|<div align="right" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<< right[cls , "title"]\nfoo\n>>>!, { :amazon_dtp_mode => true })
    assert_convert(%Q|<div align="right" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<< r[cls , "title"]\nfoo\n>>>!, { :amazon_dtp_mode => true })

    # enable_id
    assert_convert(%Q|<div style="text-align:right;" id="id" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<<right[ id , cls , "title" ]\nfoo\n>>>!, { :enable_id => true })
    assert_convert(%Q|<div style="text-align:right;" id="id" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<<r[ id , cls , "title" ]\nfoo\n>>>!, { :enable_id => true })
    assert_convert(%Q|<div align="right" id="id" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<<right[ id , cls , "title"]\nfoo\n>>>!, { :amazon_dtp_mode => true, :enable_id => true })
  end

  def test_left
    # normal
    assert_convert(%Q|<div style="text-align:left;">\n<p>foo</p>\n</div>\n|,
                   "<<<left\nfoo\n>>>")
    assert_convert(%Q|<div style="text-align:left;">\n<p>foo</p>\n</div>\n|,
                   "<<<l\nfoo\n>>>")
    assert_convert(%Q|<div style="text-align:left;">\n<p>foo</p>\n</div>\n|,
                   "<<< left\nfoo\n>>>")
    assert_convert(%Q|<div style="text-align:left;">\n<p>foo</p>\n</div>\n|,
                   "<<< l\nfoo\n>>>")
    # amazon
    assert_convert(%Q|<div align="left">\n<p>foo</p>\n</div>\n|,
                   "<<<left\nfoo\n>>>", { :amazon_dtp_mode => true })
    assert_convert(%Q|<div align="left">\n<p>foo</p>\n</div>\n|,
                   "<<<l\nfoo\n>>>", { :amazon_dtp_mode => true })
    assert_convert(%Q|<div align="left">\n<p>foo</p>\n</div>\n|,
                   "<<< left\nfoo\n>>>", { :amazon_dtp_mode => true })
    assert_convert(%Q|<div align="left">\n<p>foo</p>\n</div>\n|,
                   "<<< l\nfoo\n>>>", { :amazon_dtp_mode => true })
  end

  def test_left_with_attr
    assert_convert(%Q|<div style="text-align:left;" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<<left[ cls , "title" ]\nfoo\n>>>!)
    assert_convert(%Q|<div style="text-align:left;" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<< left[ cls , "title" ]\nfoo\n>>>!)
    assert_convert(%Q|<div style="text-align:left;" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<<l[ cls , "title" ]\nfoo\n>>>!)
    assert_convert(%Q|<div style="text-align:left;" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<< l[ cls , "title" ]\nfoo\n>>>!)

    # amazon
    assert_convert(%Q|<div align="left" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<< left[cls , "title"]\nfoo\n>>>!, { :amazon_dtp_mode => true })
    assert_convert(%Q|<div align="left" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<< l[cls , "title"]\nfoo\n>>>!, { :amazon_dtp_mode => true })

    # enable_id
    assert_convert(%Q|<div style="text-align:left;" id="id" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<<left[ id , cls , "title" ]\nfoo\n>>>!, { :enable_id => true })
    assert_convert(%Q|<div style="text-align:left;" id="id" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<<l[ id , cls , "title" ]\nfoo\n>>>!, { :enable_id => true })
    assert_convert(%Q|<div align="left" id="id" class="cls" title="title">\n<p>foo</p>\n</div>\n|,
                   %Q!<<<left[ id , cls , "title"]\nfoo\n>>>!, { :amazon_dtp_mode => true, :enable_id => true })
  end

  def test_pre
    # normal
    assert_convert(%Q|<pre>foo</pre>\n|,
                   "<<<pre\nfoo\n>>>")
    assert_convert(%Q|<pre>foo</pre>\n|,
                   "<<<p\nfoo\n>>>")
    assert_convert(%Q|<pre>foo</pre>\n|,
                   "<<< pre\nfoo\n>>>")
    assert_convert(%Q|<pre>foo</pre>\n|,
                   "<<< p\nfoo\n>>>")

    # breakline
    assert_convert(%Q!<pre>foo\n fuga</pre>\n!,
                   %Q|<<<p\nfoo\n fuga\n>>>|)
    # multi paragraph
    assert_convert(%Q!<pre>foo\nbar\n\nbaz</pre>\n!,
                   %Q|<<<p\nfoo\nbar\n\nbaz\n>>>|)
    # header
    assert_convert(%Q|<pre>! foo</pre>\n|,
                   %Q|<<<p\n! foo\n>>>|)
    # thematic break
    assert_convert(%Q!<pre>----</pre>\n!,
                   %Q|<<<p\n----\n>>>|)
    # modifier
    assert_convert(%Q!<pre>a<em>foo</em>b</pre>\n!,
                   %Q|<<<p\na{'foo'}b\n>>>|)
    # list
    assert_convert(%Q!<pre>* foo</pre>\n!,
                   %Q|<<<p\n* foo\n>>>|)
    # list with block
    assert_convert(%Q!<pre>*(((\nfoo\n bar\n)))</pre>\n!,
                   %Q|<<<p\n*(((\nfoo\n bar\n)))\n>>>|)
    # list with block
    assert_convert(%Q!<pre>* (((\nfoo\n bar\n)))</pre>\n!,
                   %Q|<<<p\n* (((\nfoo\n bar\n)))\n>>>|)
    # definition lists
    assert_convert(%Q!<pre>;foo\n:bar</pre>\n!,
                   %Q|<<<p\n;foo\n:bar\n>>>|)
    # definition lists with block
    assert_convert(%Q!<pre>;foo\n:(((\nbar\n)))</pre>\n!,
                   %Q|<<<p\n;foo\n:(((\nbar\n)))\n>>>|)
    # table
    assert_convert(%Q!<pre>||foo</pre>\n!,
                   %Q!<<<p\n||foo\n>>>!)
    # table with block
    assert_convert(%Q!<pre>||(((\nfoo\n)))</pre>\n!,
                   %Q!<<<p\n||(((\nfoo\n)))\n>>>!)
    # block plugin is converted into inline
    assert_convert(%Q!<pre>{{'test'}}</pre>\n!,
                   %Q!<<<p\n{{'test'}}\n>>>!)
    assert_convert(%Q!<pre><span class=\"plugin\">{{'test'}}</span></pre>\n!,
                   %Q!<<<p\n{{'test'}}\n>>>!, { :evaluate_plugins_in_pre => true })
    # inline plugin
    assert_convert(%Q!<pre>a{{'test'}}a</pre>\n!,
                   %Q!<<<p\na{{'test'}}a\n>>>!)
    assert_convert(%Q!<pre>a<span class=\"plugin\">{{'test'}}</span>a</pre>\n!,
                   %Q!<<<p\na{{'test'}}a\n>>>!, { :evaluate_plugins_in_pre => true })

    # nesting
    ## cannot nest other block elements
    assert_convert(%Q!<pre>&lt;&lt;&lt;d\nfoo</pre>\n<p>&gt;&gt;&gt;</p>\n!,
                   %Q!<<<p\n<<<d\nfoo\n>>>\n>>>!)

    # not pre
    assert_convert(%Q!<p>&lt;&lt;&lt;pre a\nfoo\n&gt;&gt;&gt;</p>\n!,
                   %Q|<<<pre a\nfoo\n>>>|)
    assert_convert(%Q!<p>&lt;&lt;&lt;p a\nfoo\n&gt;&gt;&gt;</p>\n!,
                   %Q|<<<p a\nfoo\n>>>|)

    # backtracking
    assert_convert(%Q!<p>&lt;&lt;&lt;p\nfoo</p>\n!,
                   %Q!<<<p\nfoo\n!)
    assert_convert(%Q!<p>&lt;&lt;&lt;p<br />\nfoo</p>\n!,
                   %Q!<<<p\n foo\n!)

    # not backtracking
    assert_convert(%Q!<pre>&lt;&lt;&lt;p\nfoo</pre>\n!,
                   %Q!<<<p\n<<<p\nfoo\n>>>!)

    # workaround to display '>>>' in pre
    assert_convert(%Q!<pre>&lt;&lt;&lt;p\nfoo\n&gt;&gt;&gt; </pre>\n!,
                   %Q|<<<p\n<<<p\nfoo\n>>> \n>>>|)
  end

  def test_pre_with_attr
    assert_convert(%Q|<pre class="cls" title="title">bar</pre>\n|,
                   %Q|<<<pre[ cls , "title" ]\nbar\n>>>|)
    assert_convert(%Q|<pre class="cls" title="title">bar</pre>\n|,
                   %Q|<<< pre[ cls , "title" ]\nbar\n>>>|)
    assert_convert(%Q|<pre class="cls" title="title">bar</pre>\n|,
                   %Q|<<<p[ cls , "title" ]\nbar\n>>>|)
    assert_convert(%Q|<pre class="cls" title="title">bar</pre>\n|,
                   %Q|<<< p[ cls , "title" ]\nbar\n>>>|)

    # enable_id
    assert_convert(%Q|<pre id="id" class="cls" title="title">bar</pre>\n|,
                   %Q|<<<pre[ id , cls , "title" ]\nbar\n>>>|, { :enable_id => true })
    assert_convert(%Q|<pre id="id" class="cls" title="title">bar</pre>\n|,
                   %Q|<<<p[ id , cls , "title" ]\nbar\n>>>|, { :enable_id => true })
  end

  def test_pre_asis
    assert_convert(%Q|<pre>foo</pre>\n|,
                   "<<<pre_asis\nfoo\n>>>")
    assert_convert(%Q|<pre>foo</pre>\n|,
                   "<<<p_a\nfoo\n>>>")
    assert_convert(%Q|<pre>foo</pre>\n|,
                   "<<<pa\nfoo\n>>>")
    assert_convert(%Q|<pre>foo</pre>\n|,
                   "<<< pre_asis\nfoo\n>>>")

    # breakline
    assert_convert(%Q!<pre>foo\n fuga</pre>\n!,
                   %Q|<<<pa\nfoo\n fuga\n>>>|)
    # multi paragraph
    assert_convert(%Q!<pre>foo\nbar\n\nbaz</pre>\n!,
                   %Q|<<<pa\nfoo\nbar\n\nbaz\n>>>|)
    # header
    assert_convert(%Q|<pre>! foo</pre>\n|,
                   %Q|<<<pa\n! foo\n>>>|)
    # thematic break
    assert_convert(%Q!<pre>----</pre>\n!,
                   %Q|<<<pa\n----\n>>>|)
    # modifier
    assert_convert(%Q!<pre>a{'foo'}b</pre>\n!,
                   %Q|<<<pa\na{'foo'}b\n>>>|)
    # list
    assert_convert(%Q!<pre>* foo</pre>\n!,
                   %Q|<<<pa\n* foo\n>>>|)
    # list with block
    assert_convert(%Q!<pre>*(((\nfoo\n bar\n)))</pre>\n!,
                   %Q|<<<pa\n*(((\nfoo\n bar\n)))\n>>>|)
    assert_convert(%Q!<pre>* (((\nfoo\n bar\n)))</pre>\n!,
                   %Q|<<<pa\n* (((\nfoo\n bar\n)))\n>>>|)
    # definition lists
    assert_convert(%Q!<pre>;foo\n:bar</pre>\n!,
                   %Q|<<<pa\n;foo\n:bar\n>>>|)
    # definition lists with block
    assert_convert(%Q!<pre>;foo\n:(((\nbar\n)))</pre>\n!,
                   %Q|<<<pa\n;foo\n:(((\nbar\n)))\n>>>|)
    # table
    assert_convert(%Q!<pre>||foo</pre>\n!,
                   %Q!<<<pa\n||foo\n>>>!)
    # table with block
    assert_convert(%Q!<pre>||(((\nfoo\n)))</pre>\n!,
                   %Q!<<<pa\n||(((\nfoo\n)))\n>>>!)
    # block plugin is converted into inline
    assert_convert(%Q!<pre>{{'test'}}</pre>\n!,
                   %Q!<<<pa\n{{'test'}}\n>>>!)
    # never execute plugins
    assert_convert(%Q!<pre>{{'test'}}</pre>\n!,
                   %Q!<<<pa\n{{'test'}}\n>>>!, { :evaluate_plugins_in_pre => true })
    # inline plugin
    assert_convert(%Q!<pre>a{{'test'}}a</pre>\n!,
                   %Q!<<<pa\na{{'test'}}a\n>>>!)
    # never execute plugins
    assert_convert(%Q!<pre>a{{'test'}}a</pre>\n!,
                   %Q!<<<pa\na{{'test'}}a\n>>>!, { :evaluate_plugins_in_pre => true })

    # nesting
    ## cannot nest other block elements
    assert_convert(%Q!<pre>&lt;&lt;&lt;d\nfoo</pre>\n<p>&gt;&gt;&gt;</p>\n!,
                   %Q!<<<pa\n<<<d\nfoo\n>>>\n>>>!)

    # not pre
    assert_convert(%Q!<p>&lt;&lt;&lt;pre_asis a\nfoo\n&gt;&gt;&gt;</p>\n!,
                   %Q|<<<pre_asis a\nfoo\n>>>|)
    assert_convert(%Q!<p>&lt;&lt;&lt;pa a\nfoo\n&gt;&gt;&gt;</p>\n!,
                   %Q|<<<pa a\nfoo\n>>>|)

    # backtracking
    assert_convert(%Q!<p>&lt;&lt;&lt;pa\nfoo</p>\n!,
                   %Q!<<<pa\nfoo\n!)
    assert_convert(%Q!<p>&lt;&lt;&lt;pa<br />\nfoo</p>\n!,
                   %Q!<<<pa\n foo\n!)

    # not backtracking
    assert_convert(%Q!<pre>&lt;&lt;&lt;pa\nfoo</pre>\n!,
                   %Q!<<<pa\n<<<pa\nfoo\n>>>!)

    # workaround to display '>>>' in pre
    assert_convert(%Q!<pre>&lt;&lt;&lt;pa\nfoo\n&gt;&gt;&gt; </pre>\n!,
                   %Q|<<<pa\n<<<pa\nfoo\n>>> \n>>>|)
  end

  def test_pre_asis_with_attr
    assert_convert(%Q|<pre class="cls" title="title">bar</pre>\n|,
                   %Q|<<<pre_asis[ cls , "title" ]\nbar\n>>>|)
    assert_convert(%Q|<pre class="cls" title="title">bar</pre>\n|,
                   %Q|<<< pre_asis[ cls , "title" ]\nbar\n>>>|)
    assert_convert(%Q|<pre class="cls" title="title">bar</pre>\n|,
                   %Q|<<<p_a[ cls , "title" ]\nbar\n>>>|)
    assert_convert(%Q|<pre class="cls" title="title">bar</pre>\n|,
                   %Q|<<< p_a[ cls , "title" ]\nbar\n>>>|)
    assert_convert(%Q|<pre class="cls" title="title">bar</pre>\n|,
                   %Q|<<<pa[ cls , "title" ]\nbar\n>>>|)
    assert_convert(%Q|<pre class="cls" title="title">bar</pre>\n|,
                   %Q|<<< pa[ cls , "title" ]\nbar\n>>>|)

    # enable_id
    assert_convert(%Q|<pre id="id" class="cls" title="title">bar</pre>\n|,
                   %Q|<<<pre_asis[ id , cls , "title" ]\nbar\n>>>|, { :enable_id => true })
    assert_convert(%Q|<pre id="id" class="cls" title="title">bar</pre>\n|,
                   %Q|<<<p_a[ id , cls , "title" ]\nbar\n>>>|, { :enable_id => true })
    assert_convert(%Q|<pre id="id" class="cls" title="title">bar</pre>\n|,
                   %Q|<<<pa[ id , cls , "title" ]\nbar\n>>>|, { :enable_id => true })
  end

  def test_asis
    assert_convert(%Q|<p>foo</p>\n|,
                   "<<<asis\nfoo\n>>>")
    assert_convert(%Q|<p>foo</p>\n|,
                   "<<<a\nfoo\n>>>")
    assert_convert(%Q|<p>foo</p>\n|,
                   "<<< asis\nfoo\n>>>")
    assert_convert(%Q|<p>foo</p>\n|,
                   "<<< a\nfoo\n>>>")

    # breakline
    assert_convert(%Q!<p>foo<br />\n fuga</p>\n!,
                   %Q|<<<a\nfoo\n fuga\n>>>|)
    # multi paragraph
    assert_convert(%Q!<p>foo<br />\nbar<br />\n<br />\nbaz</p>\n!,
                   %Q|<<<a\nfoo\nbar\n\nbaz\n>>>|)
    # header
    assert_convert(%Q|<p>! foo</p>\n|,
                   %Q|<<<a\n! foo\n>>>|)
    # thematic break
    assert_convert(%Q!<p>----</p>\n!,
                   %Q|<<<a\n----\n>>>|)
    # modifier
    assert_convert(%Q!<p>a{'foo'}b</p>\n!,
                   %Q|<<<a\na{'foo'}b\n>>>|)
    # list
    assert_convert(%Q!<p>* foo</p>\n!,
                   %Q|<<<a\n* foo\n>>>|)
    # list with block
    assert_convert(%Q!<p>*(((<br />\nfoo<br />\n bar<br />\n)))</p>\n!,
                   %Q|<<<a\n*(((\nfoo\n bar\n)))\n>>>|)
    assert_convert(%Q!<p>* (((<br />\nfoo<br />\n bar<br />\n)))</p>\n!,
                   %Q|<<<a\n* (((\nfoo\n bar\n)))\n>>>|)
    # definition lists
    assert_convert(%Q!<p>;foo<br />\n:bar</p>\n!,
                   %Q|<<<a\n;foo\n:bar\n>>>|)
    # definition lists with block
    assert_convert(%Q!<p>;foo<br />\n:(((<br />\nbar<br />\n)))</p>\n!,
                   %Q|<<<a\n;foo\n:(((\nbar\n)))\n>>>|)
    # table
    assert_convert(%Q!<p>||foo</p>\n!,
                   %Q!<<<a\n||foo\n>>>!)
    # table with block
    assert_convert(%Q!<p>||(((<br />\nfoo<br />\n)))</p>\n!,
                   %Q!<<<a\n||(((\nfoo\n)))\n>>>!)
    # block plugin is converted into inline
    assert_convert(%Q!<p>{{'test'}}</p>\n!,
                   %Q!<<<a\n{{'test'}}\n>>>!)
    # never execute plugins
    assert_convert(%Q!<p>{{'test'}}</p>\n!,
                   %Q!<<<a\n{{'test'}}\n>>>!, { :evaluate_plugins_in_pre => true })
    # inline plugin
    assert_convert(%Q!<p>a{{'test'}}a</p>\n!,
                   %Q!<<<a\na{{'test'}}a\n>>>!)
    # never execute plugins
    assert_convert(%Q!<p>a{{'test'}}a</p>\n!,
                   %Q!<<<a\na{{'test'}}a\n>>>!, { :evaluate_plugins_in_pre => true })

    # nesting
    ## cannot nest other block elements
    assert_convert(%Q!<p>&lt;&lt;&lt;d<br />\nfoo</p>\n<p>&gt;&gt;&gt;</p>\n!,
                   %Q!<<<a\n<<<d\nfoo\n>>>\n>>>!)

    # not pre
    assert_convert(%Q!<p>&lt;&lt;&lt;asis a\nfoo\n&gt;&gt;&gt;</p>\n!,
                   %Q|<<<asis a\nfoo\n>>>|)
    assert_convert(%Q!<p>&lt;&lt;&lt;a a\nfoo\n&gt;&gt;&gt;</p>\n!,
                   %Q|<<<a a\nfoo\n>>>|)

    # backtracking
    assert_convert(%Q!<p>&lt;&lt;&lt;a\nfoo</p>\n!,
                   %Q!<<<a\nfoo\n!)
    assert_convert(%Q!<p>&lt;&lt;&lt;a<br />\nfoo</p>\n!,
                   %Q!<<<a\n foo\n!)

    # not backtracking
    assert_convert(%Q!<p>&lt;&lt;&lt;a<br />\nfoo</p>\n!,
                   %Q!<<<a\n<<<a\nfoo\n>>>!)

    # workaround to display '>>>' in pre
    assert_convert(%Q!<p>&lt;&lt;&lt;a<br />\nfoo<br />\n&gt;&gt;&gt; </p>\n!,
                   %Q|<<<a\n<<<a\nfoo\n>>> \n>>>|)
  end

  def test_asis_with_attr
    assert_convert(%Q|<p class="cls" title="title">foo</p>\n|,
                   %Q!<<<asis[ cls , "title" ]\nfoo\n>>>!)
    assert_convert(%Q|<p class="cls" title="title">foo</p>\n|,
                   %Q!<<<a[ cls , "title" ]\nfoo\n>>>!)
    assert_convert(%Q|<p class="cls" title="title">foo</p>\n|,
                   %Q!<<< asis[ cls , "title" ]\nfoo\n>>>!)
    assert_convert(%Q|<p class="cls" title="title">foo</p>\n|,
                   %Q!<<< a[ cls , "title" ]\nfoo\n>>>!)

    # enable_id
    assert_convert(%Q|<p id="id" class="cls" title="title">foo</p>\n|,
                   %Q!<<<asis[ id , cls , "title" ]\nfoo\n>>>!,
                   { :enable_id => true })
    assert_convert(%Q|<p id="id" class="cls" title="title">foo</p>\n|,
                   %Q!<<<a[ id , cls , "title" ]\nfoo\n>>>!,
                   { :enable_id => true })
  end

  def test_math_block
    assert_convert(%Q|<p class="math"><div class="plugin">{{mtex 'foo'}}</div>\n</p>\n|,
                   "<<<math\nfoo\n>>>")
    assert_convert(%Q|<p class="math"><div class="plugin">{{mtex 'foo'}}</div>\n</p>\n|,
                   "<<<m\nfoo\n>>>")
    assert_convert(%Q|<p class="math"><div class="plugin">{{mtex 'foo'}}</div>\n</p>\n|,
                   "<<< math\nfoo\n>>>")
    assert_convert(%Q|<p class="math"><div class="plugin">{{mtex 'foo'}}</div>\n</p>\n|,
                   "<<< m\nfoo\n>>>")

    # disable math tag
    assert_convert(%Q|<p>&lt;&lt;&lt;math\nfoo\n&gt;&gt;&gt;</p>\n|,
                   "<<<math\nfoo\n>>>", { :enable_math => false })
  end

  def test_math_block_with_attr
    assert_convert(%Q|<p class="math cls" title="title"><div class="plugin">{{mtex 'foo'}}</div>\n</p>\n|,
                   %Q!<<<math[ cls , "title"]\nfoo\n>>>!)
    assert_convert(%Q|<p class="math cls" title="title"><div class="plugin">{{mtex 'foo'}}</div>\n</p>\n|,
                   %Q!<<<m[ cls , "title"]\nfoo\n>>>!)
    assert_convert(%Q|<p class="math cls" title="title"><div class="plugin">{{mtex 'foo'}}</div>\n</p>\n|,
                   %Q!<<< math[ cls , "title"]\nfoo\n>>>!)
    assert_convert(%Q|<p class="math cls" title="title"><div class="plugin">{{mtex 'foo'}}</div>\n</p>\n|,
                   %Q!<<< m[ cls , "title"]\nfoo\n>>>!)

    # enable_id
    assert_convert(%Q|<p id="id" class="math cls" title="title"><div class="plugin">{{mtex 'foo'}}</div>\n</p>\n|,
                   %Q!<<<math[ id , cls , "title"]\nfoo\n>>>!, { :enable_id => true })
  end



  def test_plugin
    assert_convert("<div class=\"plugin\">{{foo}}</div>\n",
                   "{{foo}}")
    assert_convert("<p>a<span class=\"plugin\">{{foo}}</span>b</p>\n",
                   "a{{foo}}b")
    assert_convert("<p><span class=\"plugin\">{{foo}}</span></p>\n",
                   "\\{{foo}}")
    assert_convert("<p>a{{foo</p>\n",
                   "a{{foo")
    assert_convert("<p>foo}}b</p>\n",
                   "foo}}b")
    assert_convert("<p><span class=\"plugin\">{{foo}}</span>\na</p>\n",
                   "{{foo}}\na")
    assert_convert("<div class=\"plugin\">{{foo}}</div>\n<p>a</p>\n",
                   "{{foo}}\n\na")
  end

  def test_plugin_with_attr
    # not supported
    assert_convert(%Q!<div class=\"plugin\">{{[ cls , "title" ]foo}}</div>\n!,
                   %Q!{{[ cls , "title" ]foo}}!)
    # collect result for plugin
    assert_convert(%Q!<p><span class="cls" title="title"><span class="plugin">{{foo}}</span></span></p>\n!,
                   %Q![ cls , "title" ]{{foo}}!)
  end

  def test_plugin_with_quotes
    assert_convert("<div class=\"plugin\">{{foo(\"}}\")}}</div>\n",
                   '{{foo("}}")}}')
    assert_convert("<div class=\"plugin\">{{foo(\'}}\')}}</div>\n",
                   "{{foo('}}')}}")
    assert_convert("<div class=\"plugin\">{{foo(\'\n}}\n\')}}</div>\n",
                   "{{foo('\n}}\n')}}")
  end

  def test_plugin_with_meta_char
    assert_convert("<div class=\"plugin\">{{foo(\"a\\\"b\")}}</div>\n",
                   '{{foo("a\\"b")}}')
    assert_convert("<div class=\"plugin\">{{foo(\"&lt;a&gt;\")}}</div>\n",
                   '{{foo("<a>")}}')
    assert_convert("<p>a<span class=\"plugin\">{{foo(\"&lt;a&gt;\")}}</span></p>\n",
                   'a{{foo("<a>")}}')
  end

  def test_plugin_with_default_syntax
    # test HikiDoc#valid_plugin_syntax?
    # default syntax checking pairs of quote like "..." or '...'
    assert_convert(%q!<p>{{'}}</p>! + "\n",
                   %q!{{'}}!)
    assert_convert(%q!<div class="plugin">{{''}}</div>! + "\n",
                   %q!{{''}}!)
    assert_convert(%q!<p>{{'"}}</p>! + "\n",
                   %q!{{'"}}!) # "
    assert_convert(%q!<div class="plugin">{{'\''}}</div>! + "\n",
                   %q!{{'\''}}!)
    assert_convert(%q!<div class="plugin">{{'abc\\\\'}}</div>! + "\n",
                   %q!{{'abc\\\\'}}!)
    assert_convert(%q!<div class="plugin">{{\"""}}</div>! + "\n",
                   %q!{{\"""}}!)
    assert_convert(%q!<div class="plugin">{{"ab\c"}}</div>! + "\n",
                   %q!{{"ab\c"}}!)
  end

  def test_plugin_with_custom_syntax
    assert_convert(%Q!<p>{{&lt;&lt;"End"\nfoo's bar\nEnd\n}}</p>\n!,
                   %Q!{{<<"End"\nfoo's bar\nEnd\n}}!)

    options = {:plugin_syntax => method(:custom_valid_plugin_syntax?)}
    assert_convert(%Q|<div class="plugin">{{&lt;&lt;"End"\nfoo's bar\nEnd\n}}</div>\n|,
                   %Q!{{<<"End"\nfoo's bar\nEnd\n}}!,
                   options)
    assert_convert(%Q|<div class="plugin">{{&lt;&lt;"End"\nfoo\nEnd}}</div>\n|,
                   %Q!{{<<"End"\nfoo\nEnd}}!,
                   options)
  end

  def test_multi_line_plugin
    assert_convert(<<-END_OF_EXPECTED, <<-END_OF_INPUT)
<div class="plugin">{{&lt;&lt;TEST2
 test2
TEST2}}</div>
                   END_OF_EXPECTED
{{<<TEST2
 test2
TEST2}}
                   END_OF_INPUT

    assert_convert(<<-END_OF_EXPECTED, <<-END_OF_INPUT)
<div class="plugin">{{&lt;&lt;TEST
&lt;&lt;&lt;
here is not pre but plugin.
&gt;&gt;&gt;
TEST}}</div>
                   END_OF_EXPECTED
{{<<TEST
<<<
here is not pre but plugin.
>>>
TEST}}
                   END_OF_INPUT
  end

  def test_div_and_plugin
    assert_convert(%Q|<div align="center">\n<div class=\"plugin\">{{foo}}</div>\n</div>\n|,
                   "<<<c\n{{foo}}\n>>>", { :amazon_dtp_mode => true })
    assert_convert("<div class=\"plugin\">{{foo\n 1}}</div>\n",
                   "{{foo\n 1}}")
  end

  def test_plugin_in_modifier
    assert_convert("<p><strong><span class=\"plugin\">{{foo}}</span></strong></p>\n",
                   "{''{{foo}}''}")
    assert_convert("<p><em><span class=\"plugin\">{{foo}}</span></em></p>\n",
                   "{'{{foo}}'}")
  end

  if Object.const_defined?(:Syntax)

    def test_syntax_ruby
      assert_convert("<center><span class=\"keyword\">class </span><span class=\"class\">A</span>\n  <span class=\"keyword\">def </span><span class=\"method\">foo</span><span class=\"punct\">(</span><span class=\"ident\">bar</span><span class=\"punct\">)</span>\n  <span class=\"keyword\">end</span>\n<span class=\"keyword\">end</span></center>\n",
                     "<<< ruby\nclass A\n  def foo(bar)\n  end\nend\n>>>")
      assert_convert("<center><span class=\"keyword\">class </span><span class=\"class\">A</span>\n  <span class=\"keyword\">def </span><span class=\"method\">foo</span><span class=\"punct\">(</span><span class=\"ident\">bar</span><span class=\"punct\">)</span>\n  <span class=\"keyword\">end</span>\n<span class=\"keyword\">end</span></center>\n",
                     "<<< Ruby\nclass A\n  def foo(bar)\n  end\nend\n>>>")
      assert_convert("<center><span class=\"punct\">'</span><span class=\"string\">a&lt;&quot;&gt;b</span><span class=\"punct\">'</span></center>\n",
                     "<<< ruby\n'a<\">b'\n>>>")
    end
  end

  private
  def assert_convert(expected, markup, options={}, message=nil)
    assert_equal(expected, HikiDoc.to_xhtml(markup, options), message)
  end

  def custom_valid_plugin_syntax?(code)
    eval("BEGIN {return true}\n#{code}", nil, "(plugin)", 0)
  rescue SyntaxError
    false
  end
end

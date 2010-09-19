# -*- coding: utf-8 -*-
# Copyright (c) 2005, Kazuhiko <kazuhiko@fdiary.net>
# Copyright (c) 2007 Minero Aoki
# Copyright (c) 2010 Hideki Sakamoto
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above
#       copyright notice, this list of conditions and the following
#       disclaimer in the documentation and/or other materials provided
#       with the distribution.
#     * Neither the name of the HikiDoc nor the names of its
#       contributors may be used to endorse or promote products derived
#       from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require "stringio"
require "strscan"
require "uri"
begin
  require "syntax/convertors/html"
rescue LoadError
end

class HikiDoc
  VERSION = "0.0.6a" # FIXME

  class Error < StandardError
  end

  class UnexpectedError < Error
  end

  def HikiDoc.to_html(src, options = {})
    new(HTMLOutput.new(">"), options).compile(src)
  end

  def HikiDoc.to_xhtml(src, options = {})
    new(HTMLOutput.new(" />"), options).compile(src)
  end

  def initialize(output, options = {})
    @output = output
    @options = default_options.merge(options)
    @header_re = nil
    @level = options[:level] || 1
    @plugin_syntax = options[:plugin_syntax] || method(:valid_plugin_syntax?)
  end

  def compile(src)
    @output.reset
    escape_plugin_blocks(src) {|escaped|
      compile_blocks escaped
      @output.finish
    }
  end

  # for backward compatibility
  def to_html
    $stderr.puts("warning: HikiDoc#to_html is deprecated. Please use HikiDoc.to_html or HikiDoc.to_xhtml instead.")
    self.class.to_html(@output, @options)
  end

  private

  def default_options
    {
      :allow_bracket_inline_image => true,
      :evaluate_plugins_in_pre => false,
      :use_wiki_name => true,
      :use_not_wiki_name => true,
      :amazon_dtp_mode => false,
      :enable_id => false,
      :enable_math => true,
      :debug => false,
    }
  end

  def get_attr(str)
    if m = /\A#{tag_attributes_re}/.match(str)
      str = m.post_match
p restore_plugin_block(m[0])[1..-2] if @options[:debug]
      @output.push_attr(@options[:enable_id] ? restore_plugin_block(m[0])[1..-2] : ',' + restore_plugin_block(m[0])[1..-2])
    end
    str
  end

  #
  # Plugin
  #

  def valid_plugin_syntax?(code)
    /['"]/ !~ code.gsub(/\\\\/, "").gsub(/\\['"]/,"").gsub(/'[^']*'|"[^"]*"/m, "")
  end

  def escape_plugin_blocks(text)
    s = StringScanner.new(text)
    buf = ""
    @plugin_blocks = []
    while chunk = s.scan_until(/\{\{/)
      tail = chunk[-2, 2]
      chunk[-2, 2] = ""
      buf << chunk
      # plugin
      if block = extract_plugin_block(s)
        @plugin_blocks.push block
        buf << "\0#{@plugin_blocks.size - 1}\0"
      else
        buf << "{{"
      end
    end
    buf << s.rest
    yield(buf)
  end

  def restore_plugin_block(str)
    str.gsub(/\0(\d+)\0/) {
      "{{" + plugin_block($1.to_i) + "}}"
    }
  end

  def evaluate_plugin_block(str, buf = nil)
    buf ||= @output.container
    str.split(/(\0\d+\0)/).each do |s|
      if s[0, 1] == "\0" and s[-1, 1] == "\0"
        str = get_attr(plugin_block(s[1..-2].to_i))
        buf << @output.inline_plugin(str)
      else
        buf << @output.text(s)
      end
    end
    buf
  end

  def plugin_block(id)
    @plugin_blocks[id] or raise UnexpectedError, "must not happen: #{id.inspect}"
  end

  def extract_plugin_block(s)
    pos = s.pos
    buf = ""
    while chunk = s.scan_until(/\}\}/)
      buf << chunk
      buf.chomp!("}}")
      if @plugin_syntax.call(buf)
        return buf
      end
      buf << "}}"
    end
    s.pos = pos
    nil
  end

  #
  # Block Level
  #

  def compile_blocks(src)
    f = LineInput.new(StringIO.new(src))
    while line = f.peek
      case line
      when COMMENT_RE
        f.gets
      when HEADER_RE
        compile_header f
      when HRULE_RE
        compile_hrule f
      when LIST_RE
        compile_list f
      when DLIST_RE
        compile_dlist f
      when TABLE_RE
        compile_table f
      when block_open_re
        compile_tagged_block f
      when /\A#{tag_attributes_re}\Z/
          get_attr(f.gets)
      when /^$/
        f.gets
      else
        compile_paragraph f
      end
    end
  end

  # continuation line
  CONTINUE_RE = /\A[ \t]/
  CONTINUE = "[ \t]"

  def get_continuation_line(f)
    buf = ''
    f.while_match(CONTINUE_RE) do |line|
      buf << line
    end
    buf
  end

  COMMENT_RE = %r<\A//>

  def skip_comments(f)
    f.while_match(COMMENT_RE) do |line|
    end
  end

  HEADER_RE = /\A!+/

  def compile_header(f)
    line = f.gets
    @header_re ||= /\A!{1,#{7 - @level}}/
    level = line.slice!(@header_re).size - 1
    title = lstrip(line)
    title = get_attr(title)
    title << get_continuation_line(f)
    title = rstrip(title)

    @output.headline @level, level, compile_inline(title)
  end

  HRULE_RE = /\A----(?:\[.*\])?$/

  def compile_hrule(f)
    if m = tag_attributes_re.match(f.gets)
      get_attr(m[0])
    end
    @output.hrule
  end

  ULIST = "*"
  OLIST = "#"
  LIST_RE = /\A#{Regexp.union(ULIST, OLIST)}{1,5}/

  def output_listitem(item, f)
    return false if item && item.empty?
    item = get_attr(item)
    @output.listitem_open
    if item.nil?
      compile_element_block(f)
    else
      @output.listitem compile_inline(item)
    end
    true
  end

  def output_list_up(from, to, list_type, item, f)
    item = get_attr(item) if /\A#{tag_attributes_re}\Z/.match(item)
    (from+1).upto(to) do |i|
      @output.push_attr("") if i < to
      @output.list_open list_type
      if i < to
        @output.push_attr("")
        @output.listitem_open
      end
    end
    output_listitem item, f
  end

  def output_list_down(from, to, typestack, item, f, unclosed)
    (from-to).times do |i|
      @output.listitem_close if unclosed
      unclosed = true
      @output.list_close typestack.pop
    end
    @output.listitem_close if to > 0
    output_listitem item, f
  end

  def output_list_continue(list_type, item, f, unclosed)
    @output.listitem_close if unclosed
    if /\A#{tag_attributes_re}\Z/.match(item)
      @output.list_close list_type
      item = get_attr(item)
      @output.list_open list_type
    else
      output_listitem item, f
    end
  end

  def output_list_chenge(list_type_last, list_type_new, item, f, unclosed)
    @output.listitem_close if unclosed
    @output.list_close list_type_last
    item = get_attr(item) if /\A#{tag_attributes_re}\Z/.match(item)
    @output.list_open list_type_new
    output_listitem item, f
  end

  def compile_list(f)
    typestack = []
    level = 0
    unclosed = false
    f.while_match(LIST_RE) do |line|
      list_type = (line[0,1] == ULIST ? "ul" : "ol")
      new_level = line.slice(LIST_RE).size
      item = lstrip(line.sub(LIST_RE, ""))
      if INLINE_OPEN_RE.match(item)
        f.ungets(item)
        item = nil
      else
        item << get_continuation_line(f)
        item = rstrip(item)
      end
      if new_level > level
        (new_level - level).times { typestack.push list_type }
        unclosed = output_list_up(level, new_level, list_type, item, f)
      elsif new_level < level
        unclosed = output_list_down(level, new_level, typestack.pop(level - new_level), item, f, unclosed)
      elsif list_type == typestack.last
        unclosed = output_list_continue(list_type, item, f, unclosed)
      else
        unclosed = output_list_chenge(typestack.pop, list_type, item, f, unclosed)
        typestack.push list_type
      end
      level = new_level
      skip_comments f
    end
    output_list_down(level, 0, typestack, "", f, unclosed)
    @output.line_break
  end

  DT = ";"
  DD = ":"
  DLIST_RE = /\A#{Regexp.union(DT, DD)}/

  def compile_dlist(f)
    @output.dlist_open
    f.while_match(DLIST_RE) do |line|
      line << get_continuation_line(f)
      line.chomp!
      if line[0,1] == DD
        dd = line.sub(DLIST_RE, "")
      else
        dt, dd = line.sub(DLIST_RE, "").split(/;:/, -1)
      end

      if INLINE_OPEN_RE.match(dd)
        f.ungets(dd)
        @output.dlist_item compile_inline(dt), '' unless dt.nil? || dt.empty?
        @output.dd_open
        compile_element_block(f)
        @output.dd_close
      else
        dd = get_attr(dd) if dd
        dt = get_attr(dt) if dt
        @output.dlist_item compile_inline(dt), compile_inline(dd)
      end
      skip_comments f
    end
    @output.dlist_close
  end

  TABLE_RE = /\A(?:\[.*?\])?\|\|/

  def compile_table(f)
    lines = []
    f.while_match(TABLE_RE) do |line|
      lines.push line
      skip_comments f
    end
    @output.table_open
    lines.each do |line|
      line = get_attr(line)
      @output.table_record_open
#      split_columns(line.sub(TABLE_RE, "")).each do |col|
      # show malformed attributes.
      split_columns(line.sub(/\A\|\|/, "")).each do |col|
        mid = col.sub!(/\A!/, "") ? "table_head" : "table_data"
        span = col.slice!(/\A[\^>]*/)
        rs = span_count(span, "^")
        cs = span_count(span, ">")
        if INLINE_OPEN_RE.match(col)
          f.ungets(col)
          @output.__send__("#{mid}_open", rs, cs)
          compile_element_block(f)
          @output.__send__("#{mid}_close")
        else
          col = get_attr(col)
          @output.__send__(mid, compile_inline(col.chomp), rs, cs)
        end
      end
      @output.table_record_close
    end
    @output.table_close
  end

  def split_columns(str)
    str.split(/\|\|/, -1)
=begin
    cols = str.split(/\|\|/, -1)
    cols.pop if cols.last.chomp.empty?
    cols
=end
  end

  def span_count(str, ch)
    c = str.count(ch)
    c == 0 ? nil : c + 1
  end

  SELECTOR_RE = /[a-zA-Z][a-zA-Z0-9_:.-]*/
  SELECTORS_RE = /#{SELECTOR_RE}(?: +#{SELECTOR_RE})*/

  # allow double-quote in title
#  TITLE_RE = %r|[^\]]*|
  # disallow double-quote in title
  # TITLE_RE = %r|[^\"\]]*|
  #####
  # id and class
  #TAG_ATTRIBUTES_RE = "(\\[(?:#{SELECTOR_RE})?(?:,(?:#{SELECTOR_RE})?)?\\])?"
  # id,class and title
  #TAG_ATTRIBUTES_RE = %r<(?:\[((?:#{SELECTOR_RE}|"#{TITLE_RE}")?(?:,(?:#{SELECTOR_RE}|"#{TITLE_RE}")?(?:,(?:#{TITLE_RE})?)?)?)\])?>
  # class and title
#  TAG_ATTRIBUTES_RE = %r<(?:\[((?:#{SELECTORS_RE}|"#{TITLE_RE}")?(?:,[ \t]*(?:#{TITLE_RE}))?)\])>
#  TAG_ATTRIBUTES_RE = %r<(?:\[(?:#{SELECTORS_RE}|"#{TITLE_RE}")?(?:,[ \t]*(?:#{TITLE_RE}))?\])>
#  TAG_ATTRIBUTES_RE = %r<\[(?:#{SELECTORS_RE}|"#{TITLE_RE}"|(?:(?:#{SELECTORS_RE})?,[ \t]*){1,2}(?:"#{TITLE_RE}"|#{TITLE_RE})?)?\]>
#  TAG_ATTRIBUTES_RE = %r<\[(?:#{SELECTORS_RE}|"#{TITLE_RE}"|(?:#{SELECTORS_RE})?,[ \t]*(?:#{SELECTORS_RE}|"#{TITLE_RE}"|#{TITLE_RE})?|(?:(?:#{SELECTORS_RE})?,[ \t]*){2}(?:"#{TITLE_RE}"|#{TITLE_RE})?)?\]>

  TITLE_RE = /".+?"/
  ATTRIBUTES_RE = /#{Regexp.union(SELECTORS_RE,TITLE_RE)}/

  def tag_attributes_re
    if @options[:enable_id]
      %r<\[ *(?:#{ATTRIBUTES_RE}|(?:#{SELECTORS_RE})? *, *(?:#{ATTRIBUTES_RE})?|(?:(?:#{SELECTORS_RE})? *, *){2}(?:#{TITLE_RE})?) *\]>
    else
      %r<\[ *(?:#{ATTRIBUTES_RE}|(?:#{SELECTORS_RE})? *, *(?:#{TITLE_RE})) *\]>
    end
  end
=begin
  TITLE_RE = %r|.+?|
  def tag_attributes_re
    if @options[:enable_id]
      %r<\[ *(?:#{SELECTORS_RE}|"#{TITLE_RE}"|(?:#{SELECTORS_RE})? *, *(?:#{SELECTORS_RE}|"#{TITLE_RE}")?|(?:(?:#{SELECTORS_RE})? *, *){2}(?:"#{TITLE_RE}"|#{TITLE_RE})?) *\]>
    else
      %r<\[ *(?:#{SELECTORS_RE}|"#{TITLE_RE}"|(?:#{SELECTORS_RE})? *, *(?:"#{TITLE_RE}"|#{TITLE_RE})) *\]>
    end
  end
=end


  BLOCK_BLOCKQUOTE_RE = /b(?:lockquote)?/
  BLOCK_LEFT_RE = /l(?:eft)?/
  BLOCK_CENTER_RE = /c(?:enter)?/
  BLOCK_RIGHT_RE = /r(?:ight)?/
  BLOCK_PRE_ASIS_RE = /p(?:re)?(?:_)?a(?:sis)?/
  BLOCK_PRE_RE = /p(?:re)?/
  BLOCK_ASIS_RE = /a(?:sis)?/
  BLOCK_DIV_RE = /d(?:iv)?/
  BLOCK_MATH_RE = /m(?:ath)?/

  def block_tag_re
    if @options[:enable_math]
      /#{Regexp.union(BLOCK_BLOCKQUOTE_RE,BLOCK_LEFT_RE,BLOCK_CENTER_RE,BLOCK_RIGHT_RE,BLOCK_PRE_ASIS_RE,BLOCK_PRE_RE,BLOCK_ASIS_RE,BLOCK_DIV_RE,BLOCK_MATH_RE)}/
    else
      /#{Regexp.union(BLOCK_BLOCKQUOTE_RE,BLOCK_LEFT_RE,BLOCK_CENTER_RE,BLOCK_RIGHT_RE,BLOCK_PRE_ASIS_RE,BLOCK_PRE_RE,BLOCK_ASIS_RE,BLOCK_DIV_RE)}/
    end
  end

  def block_open_re
    /\A<<<+\s*(#{block_tag_re})? */
  end

  # for identification
  BLOCK_OPEN_RE = /\A<<</
  BLOCK_END_RE = %r|\A>>>+(?:\s*//.*)?\Z|
  BLOCK_TERMINATE_RE = /\A#{Regexp.union(BLOCK_OPEN_RE, BLOCK_END_RE)}/

  def gbl(str, rest)
    case str
    when BLOCK_DIV_RE
      "div"
    when BLOCK_BLOCKQUOTE_RE
      "blockquote"
    when BLOCK_MATH_RE
      "math"
    when BLOCK_PRE_ASIS_RE
      "pre_asis"
    when BLOCK_PRE_RE
      "pre"
    when BLOCK_ASIS_RE
      "asis"
    when BLOCK_LEFT_RE
      "left"
    when BLOCK_CENTER_RE
      "center"
    when BLOCK_RIGHT_RE
      "right"
    when nil
      tag_attributes_re.match(rest) ? "div" : "none"
    else
      nil
    end
  end

  INLINE_OPEN_RE = /\A\(\(\(\s*([a-zA-Z0-9_]+)?/
  INLINE_END_RE = %r|\A\s*\)\)\)\s*(?://.*)?\Z|
  INLINE_TABLE_RE = /\|\|!?\^*>*\s*\(\(\(/
  INLINE_LIST_RE = /[*#:]+\s*\(\(\(/ # ul,ol and dd
  INLINE_ELEMENT_RE = Regexp.union(INLINE_TABLE_RE, INLINE_LIST_RE)
  INLINE_TERMINATE_RE = Regexp.union(INLINE_END_RE, INLINE_ELEMENT_RE)

  def compile_element_block(f)
    buf = get_inline_body(f)
    if buf.class == String
      buf << get_continuation_line(f)
      @output.preformatted(compile_inline(buf.chomp))
    else
      compile_blocks buf.join("")
    end
  end

  def get_nested_inline(f)
    line_buffer = [f.gets]
    cnt = line_buffer.first.scan(INLINE_ELEMENT_RE).length
    m = INLINE_ELEMENT_RE.match(line_buffer.first) or return line_buffer.first
    cnt.times do
      while line_buffer += f.break(INLINE_TERMINATE_RE) do
        line_buffer << get_nested_inline(f) if INLINE_ELEMENT_RE.match(f.peek)
        break if INLINE_END_RE.match(f.peek) || f.eof?
      end
      line_buffer << f.gets
    end
    unless INLINE_END_RE.match(line_buffer[-1])
      first = line_buffer.shift
      line_buffer.flatten.reverse_each do |line|
        f.ungets(line)
      end
      return first
    else
      line_buffer
    end
  end

  def get_inline_body(f)
    line_buffer = []
    first = f.gets
    m = INLINE_OPEN_RE.match(first) or raise UnexpectedError, "must not happen"
    return first unless m.post_match.empty?
    while line_buffer += f.break(INLINE_TERMINATE_RE) do
      line_buffer << get_nested_inline(f) if INLINE_ELEMENT_RE.match(f.peek)
      break if INLINE_END_RE.match(f.peek) || f.eof?
    end
    unless INLINE_END_RE.match(last = f.gets)
      line_buffer.flatten.reverse_each do |line|
        f.ungets(line)
      end
      return first
    end
    line_buffer
  end

  def compile_tagged_block(f)
    buf = get_block_body(f)
    if buf.class == String
      compile_paragraph f, buf
    else
      compile_block_body buf
    end
  end

  def get_block_body(f)
    line_buffer = []
    line_buffer << f.gets
    m = block_open_re.match(line_buffer[0].chomp) or raise UnexpectedError, "must not happen"
    return line_buffer[0] unless m.post_match.empty? || tag_attributes_re.match(m.post_match)
=begin
    p line_buffer[0] if @options[:debug]
    ggg = gbl(m[1], m.post_match)
    p ggg  if @options[:debug]
    case ggg
=end
    case gbl(m[1], m.post_match)
    when "pre", "pre_asis", "asis", "math"
      line_buffer += f.break(BLOCK_END_RE)
    when "blockquote", "left", "center", "right", "div", "none"
      while line_buffer += f.break(BLOCK_TERMINATE_RE).reject {|line| COMMENT_RE =~ line } do
        line_buffer << get_block_body(f) if block_open_re.match(f.peek)
        break if BLOCK_END_RE.match(f.peek) || f.eof?
      end
    else
      return line_buffer[0]
    end
    line_buffer << f.gets   # leave this for nested backtrack
    unless BLOCK_END_RE.match(line_buffer[-1])
      preload = line_buffer.shift
      line_buffer.flatten.reverse_each do |line|
        f.ungets(line)
      end
      return preload
    end
    line_buffer
  end

  def compile_block_body(lines)
    lines.pop # leave this for nested backtrack
    m = block_open_re.match(lines.shift.chomp) or raise UnexpectedError, "must not happen"
    label = gbl(m[1], m.post_match)
p m.post_match if @options[:debug]
    str = get_attr(m.post_match)
p str if @options[:debug]
    lines.unshift(str) unless str.to_s.empty?
    @output.__send__("#{label}_open", @options)
    case label
    when "pre", "pre_asis"
      compile_pre_block(lines.flatten.join("").chomp, label == "pre_asis")
    when "asis"
      compile_asis_block(lines)
    when "math"
      compile_math_block(lines)
    else
      compile_misc_block(lines)
    end
    @output.__send__("#{label}_close")
  end

  def compile_pre_block(str, asis = false)
    if asis
      @output.preformatted(@output.text(restore_plugin_block(str)))
    else
      @output.preformatted(compile_inline(@output.escape_html(str), nil, true))
    end
  end

  def compile_asis_block(lines)
    buffer = ''
    lines.each do |line|
      if line.class == String
        buffer << @output.text(restore_plugin_block(line.chomp))
      else
        compile_block_body line
      end
      buffer << @output.break_line
      buffer << "\n"
    end
    @output.preformatted(buffer.sub(%r|#{@output.break_line}\n\z|m, ''))
  end

  def compile_math_block(lines)
    @output.math_block(lines.join("").chomp)
  end

  def compile_misc_block(lines, buf = '', cnt = 0, noout = false)
    lines.each do |line|
      if line.class == Array
        if cnt == 0
          compile_blocks buf
          compile_block_body(line)
          buf = ''
        else
          compile_misc_block(line, buf, cnt, true)
        end
      else
        cnt += line.scan(/\|\|!?\^*>*\s*\(\(\(/).length
        cnt += line.scan(/[*#]+\s*\(\(\(/).length
        buf << line
        if cnt > 0 && cnt == line.scan(INLINE_END_RE).length
          compile_blocks buf
          buf = ''
        end
        cnt -= line.scan(INLINE_END_RE).length
      end
    end
    compile_blocks buf unless buf.empty? || noout
  end

  BLANK = /\A$/
  PARAGRAPH_END_RE = Regexp.union(BLANK,
                                  HEADER_RE, HRULE_RE, LIST_RE, DLIST_RE,
                                  BLOCK_OPEN_RE, TABLE_RE)


  def compile_paragraph(f, preload = nil)
    lines = f.break(PARAGRAPH_END_RE)\
        .reject {|line| COMMENT_RE =~ line }
    lines.unshift(preload) if preload
    if lines.size == 1 and /\A\0(\d+)\0\z/ =~ strip(lines[0])
      @output.block_plugin plugin_block($1.to_i)
    else
      line_buffer = @output.container(:paragraph)
      lines.each do |line|
        line_buffer[-1] << @output.break_line if line_buffer[-1] && line.match(CONTINUE_RE)
        line = lstrip(line)
        if /\A#{tag_attributes_re}/.match(line)
          line = get_attr(line)
          line_buffer << @output.span(compile_inline(lstrip(line).chomp)) unless line.chomp.empty?
        else
          line_buffer << compile_inline(lstrip(line).chomp)
        end
      end
      @output.paragraph(line_buffer)
    end
  end

  #
  # Inline Level
  #

  BRACKET_LINK_RE = /\[\[.+?\]\]/
  URI_RE = /(?:https?|ftp|file|mailto):[A-Za-z0-9;\/?:@&=+$,\-_.!~*\'()#%]+/
  WIKI_NAME_RE = /\b(?:[A-Z]+[a-z\d]+){2,}\b/
  CONTINUATION_LINE_RE = /[\r\n]+[ \t]+/

  def inline_syntax_re(in_pre)
    if @options[:use_wiki_name]
      if @options[:use_not_wiki_name]
        if in_pre
          / (#{BRACKET_LINK_RE})
          | (#{URI_RE})
          | (#{MODIFIER_IN_PRE_RE})
          | (\^?#{WIKI_NAME_RE})
          /mxo
        else
          / (#{BRACKET_LINK_RE})
          | (#{URI_RE})
          | (#{MODIFIER_RE})
          | (\^?#{WIKI_NAME_RE})
          | (#{CONTINUATION_LINE_RE})
          /mxo
        end
      else
        if in_pre
          / (#{BRACKET_LINK_RE})
          | (#{URI_RE})
          | (#{MODIFIER_IN_PRE_RE})
          | (#{WIKI_NAME_RE})
          /mxo
        else
          / (#{BRACKET_LINK_RE})
          | (#{URI_RE})
          | (#{MODIFIER_RE})
          | (#{WIKI_NAME_RE})
          | (#{CONTINUATION_LINE_RE})
          /mxo
        end
      end
    else
      if in_pre
        / (#{BRACKET_LINK_RE})
        | (#{URI_RE})
        | (#{MODIFIER_IN_PRE_RE})
        /mxo
      else
        / (#{BRACKET_LINK_RE})
        | (#{URI_RE})
        | (#{MODIFIER_RE})
        | (#{CONTINUATION_LINE_RE})
        /mxo
      end
    end
  end

  def compile_inline(str, buf = nil, in_pre = false)
    buf ||= @output.container
    re = inline_syntax_re in_pre
    pending_str = nil
    if in_pre
      # <img />  is not allowed in <pre>
      sv = @options[:allow_bracket_inline_image]
      @options[:allow_bracket_inline_image] = false
    end
    while m = re.match(str)
      str = m.post_match

      link, uri, mod, wiki_name, cont = m[1, 5]
      unless @options[:use_wiki_name]
        cont = wiki_name
        wiki_name = nil
      end
      if wiki_name and wiki_name[0, 1] == "^"
        pending_str = m.pre_match + wiki_name[1..-1] + str
        next
      end

      pre_str = "#{pending_str}#{m.pre_match}"
      pending_str = nil
      if in_pre && ! @options[:evaluate_plugins_in_pre]
        buf << restore_plugin_block(pre_str)
      else
        evaluate_plugin_block(pre_str, buf)
      end
      compile_inline_markup(buf, link, uri, mod, wiki_name, cont)
    end
    if in_pre && ! @options[:evaluate_plugins_in_pre]
      buf << restore_plugin_block(pending_str || str || '')
    else
      evaluate_plugin_block(pending_str || str || '', buf)
    end
    @options[:allow_bracket_inline_image] = sv if in_pre
    buf
  end

  def compile_inline_markup(buf, link, uri, mod, wiki_name, cont)
    case
    when link
      link = get_attr(link[2...-2])
      buf << compile_bracket_link(link)
    when uri
      @output.add_attr("") # dummy
      buf << compile_uri_autolink(uri)
    when mod
      buf << compile_modifier(mod)
    when wiki_name
      @output.add_attr("") # dummy
      buf << @output.wiki_name(wiki_name)
    when cont
      buf << @output.break_line
    else
      raise UnexpectedError, "must not happen"
    end
  end

  def compile_bracket_link(link)
    if m = /\A(.*)\|/.match(link)
      title = m[0].chop
      uri = m.post_match
      fixed_uri = fix_uri(uri)
      if can_image_link?(uri)
        @output.image_hyperlink(fixed_uri, title)
      else
        @output.hyperlink(fixed_uri, compile_modifier(title))
      end
    else
      fixed_link = fix_uri(link)
      if can_image_link?(link)
        @output.image_hyperlink(fixed_link)
      else
        @output.hyperlink(fixed_link, @output.text(link))
      end
    end
  end

  def can_image_link?(uri)
    image?(uri) and @options[:allow_bracket_inline_image]
  end

  def compile_uri_autolink(uri)
    if image?(uri)
      @output.image_hyperlink(fix_uri(uri))
    else
      @output.hyperlink(fix_uri(uri), @output.text(uri))
    end
  end

  def fix_uri(uri)
    if /\A(?:https?|ftp|file):(?!\/\/)/ =~ uri
      uri.sub(/\A\w+:/, "")
    else
      uri
    end
  end

  IMAGE_EXTS = %w(.jpg .jpeg .gif .png)

  def image?(uri)
    IMAGE_EXTS.include?(uri[/\.[^.]+\z/].to_s.downcase)
  end

  STRONG = "{''"
  EM = "{'"
  DEL = "{="
  BIG = "{+"
  SMALL = "{-"
  SUP = "{^^"
  SUB = "{__"
  UNDERLINE = "{_"
  TT = "{`"
  ITALIC = "{/"
  ASIS = "{!"
  CITE = "{@"
  SPAN = "{\""
  COLOR = "{~"
  MATH = "{\$"
  REFERENCE = "{&"

  STRONG_RE    = /{''.+?''}/
  EM_RE        = /{'.+?'}/
  DEL_RE       = /{=.+?=}/
  BIG_RE       = /{\+.+\+}/
  SMALL_RE     = /\{-.+-\}/
  SUP_RE       = /{\^\^.+?\^\^}/
  SUB_RE       = /{__.+?__}/
  UNDERLINE_RE = /{_.+?_}/
  ITALIC_RE    = %r<{/.+?/}>
  TT_RE        = /{`.+?`}/
  ASIS_RE      = /{!.+?!}/
  CITE_RE      = /{@.+?@}/
  SPAN_RE      = /{".+?"}/
  COLOR_RE     = /{~.+?~}/
  MATH_RE      = /{\$.+\$}/
  REFERENCE_RE = /{&(?:#[0-9]{2,5}|[a-zA-Z]{2,8}[0-9]{0,2});}/

  MODIFIER_RE = Regexp.union(STRONG_RE, EM_RE, DEL_RE, BIG_RE, SMALL_RE,
                             SUP_RE, SUB_RE, UNDERLINE_RE, ITALIC_RE, ASIS_RE,
                             SPAN_RE, CITE_RE, TT_RE, COLOR_RE, MATH_RE, REFERENCE_RE)

  MODIFIER_IN_PRE_RE = Regexp.union(STRONG_RE, EM_RE, DEL_RE, ASIS_RE,
                                    UNDERLINE_RE, ITALIC_RE, TT_RE, MATH_RE)

  MODTAG = {
    STRONG    => "strong",
    EM        => "em",
    DEL       => "del",
    BIG       => "big",
    SMALL     => "small",
    SUP       => "sup",
    SUB       => "sub",
    UNDERLINE => "underline",
    ITALIC    => "italic",
    ASIS      => "asis",
    CITE      => "cite",
    SPAN      => "span",
    TT        => 'tt',
    COLOR     => 'color',
    MATH      => 'math',
    REFERENCE => 'reference',
  }

  def compile_modifier(str)
    buf = @output.container
    while m = / (#{MODIFIER_RE})
              /xo.match(str)
      evaluate_plugin_block(m.pre_match, buf)
      case
      when chunk = m[1]
        mod, t = split_mod(chunk)
        mid = MODTAG[mod]
p t if @options[:debug]
        t = strip(get_attr(t))
p t if @options[:debug]
        buf << @output.__send__(mid, mid == "asis" ? t : compile_inline(t), @options)
      else
        raise UnexpectedError, "must not happen #{chunk}, #{m[1]}"
      end
      str = m.post_match
    end
    evaluate_plugin_block(str, buf)
    buf
  end

  def split_mod(str)
    case str
    when /\A{(?:''|\^\^|__)/
      return str[0, 3], str[3...-3]
    when /\A{['`=+\-_\/!@"~\$&]/
      return str[0, 2], str[2...-2]
    else
      raise UnexpectedError, "must not happen: #{str.inspect}"
    end
  end

  def strip(str)
    rstrip(lstrip(str))
  end

  def rstrip(str)
    str.sub(/[ \t\r\n\v\f]+\z/, "")
  end

  def lstrip(str)
    str.sub(/\A[ \t\r\n\v\f]+/, "")
  end

  module CommonOutput
    def initialize(*dummy)
      @f = nil
      @attr = Array.new
    end

    def reset
      @f = StringIO.new
      @attr = Array.new
    end

    def finish
      @f.string
    end

    def add_attr(attr, shift = false)
      if shift
        @attr.unshift attr
      else
        @attr.push attr
      end
    end

    def get_attrs
      lst = @attr.pop.to_s.split(',', -1)
      unless lst.first.to_s.match(/^[ \t]*"/)
        i = lst.shift.to_s.strip
      end
      unless lst.first.to_s.match(/^[ \t]*"/)
        c = lst.shift.to_s.strip
      end
      t = lst.join(',').sub(/\A[ \t]*"(.*)"[ \t]*\Z/,'\1').strip if lst && ! lst.empty?
      return i, c, t
    end

    def append_attr(id, cls, title)
      i, c, t = get_attrs
      nid = "#{id} #{i}".strip
      ncls = "#{cls} #{c}".strip
      ntitle = "#{title} #{t}".strip
      @attr.push("#{nid},#{ncls},#{ntitle}")
    end

    def push_attr(attr)
      @attr.push attr
    end

    def clear_attr
      @attr.clear
    end

    def attr
      buf = ''
      id, cls, title = get_attrs

      buf += %Q( id="#{id}") if id && ! id.empty?
      buf += %Q( class="#{cls}") if cls && ! cls.empty?
      buf += %Q( title="#{escape_title_attr(title)}") if title && ! title.empty?
      buf
    end

    # allow only character reference
    def escape_title_attr(str)
      buf = ""
      while m = /(#{REFERENCE_RE})/xo.match(str)
        str = m.post_match
        buf << escape_html_param(m.pre_match)
        case
        when chunk = m[1]
          mod, t = chunk[0, 2], chunk[2...-2]
          mid = MODTAG[mod]
#          t = get_attr(t).to_s.strip
          buf << __send__(mid, t)
        else
          raise UnexpectedError, "must not happen #{chunk}, #{m[1]}"
        end
      end
      buf << escape_html_param(str)
    end

    def attr_empty?
      @attr.empty?
    end

    def container(_for=nil)
      case _for
      when :paragraph
        []
      else
        ""
      end
    end
  end

  class HTMLOutput
    include CommonOutput

    def initialize(suffix = " />")
      @suffix = suffix
      super
    end

    #
    # Procedures
    #

    def headline(offset, level, title)
      @f.puts "<h#{offset + level}#{attr}>#{title}</h#{offset + level}>"
    end

    def hrule
      @f.puts "<hr#{attr}#{@suffix}"
    end

    def break_line
      "<br#{@suffix}"
    end

    def line_break
      @f.puts
    end

    def list_open(type)
      @f.puts "<#{type}#{attr}>"
    end

    def list_close(type)
      @f.print "</#{type}>"
    end

    def listitem_open
      @f.print "<li#{attr}>"
    end

    def listitem_close
      @f.puts "</li>"
    end

    def listitem(item)
      @f.print item
    end

    def dlist_open
      @f.puts "<dl#{attr}>"
    end

    def dlist_close
      @f.puts "</dl>"
    end

    def dlist_item(dt, dd)
      case
      when dd.empty?
        @f.puts "<dt#{attr}>#{dt}</dt>"
      when dt.empty?
        @f.puts "<dd#{attr}>#{dd}</dd>"
      else
        @f.puts "<dt#{attr}>#{dt}</dt>"
        @f.puts "<dd#{attr}>#{dd}</dd>"
      end
    end

    def dd_open
      @f.print "<dd#{attr}>"
    end

    def dd_close
      @f.puts "</dd>"
    end

    def table_open
      @f.puts %Q(<table#{attr}>)
    end

    def table_close
      @f.puts "</table>"
    end

    def table_record_open
      @f.print "<tr#{attr}>"
    end

    def table_record_close
      @f.puts "</tr>"
    end

    def table_head(item, rs, cs)
      @f.print "<th#{tdattr(rs, cs)}#{attr}>#{item}</th>"
    end

    def table_head_open(rs, cs)
      @f.print "<th#{tdattr(rs, cs)}#{attr}>"
    end

    def table_head_close
      @f.print "</th>"
    end

    def table_data(item, rs, cs)
      @f.print "<td#{tdattr(rs, cs)}#{attr}>#{item}</td>"
    end

    def table_data_open(rs,cs)
      @f.print "<td#{tdattr(rs, cs)}#{attr}>"
    end

    def table_data_close
      @f.print "</td>"
    end

    def tdattr(rs, cs)
      buf = ""
      buf << %Q( rowspan="#{rs}") if rs
      buf << %Q( colspan="#{cs}") if cs
      buf
    end
    private :tdattr

    def add_tag_class(opts, cls)
      case opts.to_a.size
      when 1
        opts << cls
      when 2
        if opts[1].nil?
          opts[1] = cls
        else
          opts[1] << " #{cls}"
        end
      else
        opts = ["", cls]
      end
      opts
    end

    def tag_opts(id = nil, cls = nil)
      opt = ''
      opt = %Q| id="#{id}"| unless id.to_s.empty?
      opt << %Q| class="#{cls}"| unless cls.to_s.empty?
      opt
    end

    def blockquote_open(opts = {})
      @f.puts "<blockquote#{attr}>"
    end

    def blockquote_close
      @f.puts "</blockquote>"
    end

    def div_open_with_align(align, opts = {})
      if opts[:amazon_dtp_mode]
        @f.puts %Q|<div align="#{align}"#{attr}>|
      else
        @f.puts %Q|<div style="text-align:#{align};"#{attr}>|
      end
    end

    def none_open(opts = {})
    end

    def none_close
    end

    def div_open(opts = {})
      @f.puts "<div#{attr}>"
    end

    def div_close
      @f.puts "</div>"
    end

    def left_open(opts = {})
      div_open_with_align("left", opts)
    end

    def center_open(opts = {})
      div_open_with_align("center", opts)
    end

    def right_open(opts = {})
      div_open_with_align("right", opts)
    end

    alias left_close div_close
    alias center_close div_close
    alias right_close div_close

    def pre_open(opts = {})
      @f.print "<pre#{attr}>"
    end

    alias pre_asis_open pre_open

    def pre_close
      @f.puts "</pre>"
    end

    alias pre_asis_close pre_close

    def asis_open(opts = {})
      @f.print "<p#{attr}>"
    end

    def asis_close
      @f.puts "</p>"
    end

    def preformatted(str)
      @f.print str
    end

    def paragraph(lines)
      @f.puts "<p#{attr}>#{lines.join("\n")}</p>"
    end

    def math_open(opts = {})
      append_attr(nil, "math", nil)
      asis_open
    end

    alias math_close asis_close

    def math_block(str)
      ml = "mtex '#{str}'"
      block_plugin(ml)
    end

    def block_plugin(str)
      @f.puts %Q(<div class="plugin">{{#{escape_html(str)}}}</div>)
    end

    #
    # Functions
    #

    def hyperlink(uri, title)
      %Q(<a href="#{escape_html_param(uri)}"#{attr}>#{title}</a>)
    end

    def wiki_name(name)
      hyperlink(name, text(name))
    end

    def image_hyperlink(uri, alt = "")
#      alt ||= uri.split(/\//).last
      alt = escape_html(alt)
      %Q(<img src="#{escape_html_param(uri)}" alt="#{alt}"#{attr}#{@suffix})
    end

    def strong(item, options = {})
      "<strong#{attr}>#{item}</strong>"
    end

    def em(item, options = {})
      "<em#{attr}>#{item}</em>"
    end

    def del(item, options = {})
      "<del#{attr}>#{item}</del>"
    end

    def big(item, options = {})
      "<big#{attr}>#{item}</big>"
    end

    def small(item, options = {})
      "<small#{attr}>#{item}</small>"
    end

    def sup(item, options = {})
      "<sup#{attr}>#{item}</sup>"
    end

    def sub(item, options = {})
      "<sub#{attr}>#{item}</sub>"
    end

    def underline(item, options = {})
      "<u#{attr}>#{item}</u>"
    end

    def italic(item, options = {})
      "<i#{attr}>#{item}</i>"
    end

    def tt(item, options = {})
      "<tt#{attr}>#{item}</tt>"
    end

    def color(item, options = {})
      m = /\A(.*?):/.match(item.chomp)
      options[:amazon_dtp_mode] ? %Q|<font color="#{m[1]}"#{attr}>#{m.post_match}</font>| : %Q|<span style="color: #{m[1]};"#{attr}>#{m.post_match}</span>|
    end

    def math(item, options = {})
      append_attr(nil, "math", nil)
      str = "mtex '#{item}'"
      "<span#{attr}>#{inline_plugin(str)}</span>"
    end

    def reference(item, options = {})
      "&#{item};"
    end

    def span(item, options = {})
      "<span#{attr}>#{item}</span>"
    end

    def cite(item, options = {})
      "<cite#{attr}>#{item}</cite>"
    end

    def text(str, options = {})
      escape_html(str)
    end

    alias asis text

    def inline_plugin(src)
      %Q(<span class="plugin">{{#{escape_html(src)}}}</span>)
    end

    #
    # Utilities
    #

    def escape_html_param(str)
      escape_quote(escape_html(str))
    end

    def escape_html(text)
      text.gsub(/&/, "&amp;").gsub(/</, "&lt;").gsub(/>/, "&gt;")
    end

    def unescape_html(text)
      text.gsub(/&gt;/, ">").gsub(/&lt;/, "<").gsub(/&amp;/, "&")
    end

    def escape_quote(text)
      text.gsub(/"/, "&quot;")
    end
  end


  class LineInput
    def initialize(f)
      @input = f
      @buf = []
      @lineno = 0
      @eof_p = false
    end

    def inspect
      "\#<#{self.class} file=#{@input.inspect} line=#{lineno()}>"
    end

    def eof?
      @eof_p
    end

    def lineno
      @lineno
    end

    def gets
      unless @buf.empty?
        @lineno += 1
        return @buf.pop
      end
      return nil if @eof_p   # to avoid ARGF blocking.
      line = @input.gets
      line = line.sub(/\r\n/, "\n") if line
      @eof_p = line.nil?
      @lineno += 1
      line
    end

    def ungets(line)
      return unless line
      @lineno -= 1
      @buf.push line
      line
    end

    def peek
      line = gets()
      ungets line if line
      line
    end

    def next?
      peek() ? true : false
    end

    def skip_blank_lines
      n = 0
      while line = gets()
        unless line.strip.empty?
          ungets line
          return n
        end
        n += 1
      end
      n
    end

    def gets_if(re)
      line = gets()
      if not line or not (re =~ line)
        ungets line
        return nil
      end
      line
    end

    def gets_unless(re)
      line = gets()
      if not line or re =~ line
        ungets line
        return nil
      end
      line
    end

    def each
      while line = gets()
        yield line
      end
    end

    def while_match(re)
      while line = gets()
        unless re =~ line
          ungets line
          return
        end
        yield line
      end
      nil
    end

    def getlines_while(re)
      buf = []
      while_match(re) do |line|
        buf.push line
      end
      buf
    end

    alias span getlines_while   # from Haskell

    def until_match(re)
      while line = gets()
        if re =~ line
          ungets line
          return
        end
        yield line
      end
      nil
    end

    def getlines_until(re)
      buf = []
      until_match(re) do |line|
        buf.push line
      end
      buf
    end

    alias break getlines_until   # from Haskell

    def until_terminator(re)
      while line = gets()
        return if re =~ line   # discard terminal line
        yield line
      end
      nil
    end

    def getblock(term_re)
      buf = []
      until_terminator(term_re) do |line|
        buf.push line
      end
      buf
    end
  end
end

if __FILE__ == $0
  puts HikiDoc.to_html(ARGF.read(nil))
end

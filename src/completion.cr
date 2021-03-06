require "./completion/*"
require "option_parser"

module Completion

  class Completer

    getter last_word
    getter line
    getter fragment
    getter values

    def initialize(@program)
      @fragments = [] of Symbol
      @values = {} of String|Symbol => String|Nil
      @end_of_arguments = ->{ reply Dir.entries Dir.current }
      @listeners = {} of Symbol => -> Void
      @install = ARGV.includes? "--completion"
      @compgen = ARGV.includes? "--compgen"
      @line = ""

      if @compgen
        @comp_starts_at = ARGV.index "--compgen"
        if @comp_starts_at
          starts = Int32.cast @comp_starts_at
          @fragment = ARGV[starts + 1].to_i
          @last_word = ARGV[starts + 2]
          @line = ARGV[starts + 3]
        end
      end

      if @install
        puts installer
      end
    end

    def set_fragments(@fragments)
    end

    def on(fragment, &reply)
      @listeners[fragment] = reply
    end

    def end(&reply)
      @end_of_arguments = reply
    end

    def reply(results)
      puts results.join "\n"
    end

    def init
      if @compgen
        fragment = @fragment as Int32
        begin
          completions = @listeners[@fragments[fragment-1]]

          @line.split(" ").each_index do |i|
            @values[@fragments[i-1]] = @line.split(" ").at(i)
          end
        rescue
          completions = @end_of_arguments
        end
        completions.call
      end
    end

    def installer
      completion = "__#{@program}_completion"
      "### #{@program} completion - begin. generated by f/completion ###
if type complete &>/dev/null; then
  #{completion}() {
    COMPREPLY=( $(compgen -W '$(#{@program} --compbash --compgen \"${COMP_CWORD}\" \"${COMP_WORDS[COMP_CWORD-1]}\" \"${COMP_LINE}\")' -- \"${COMP_WORDS[COMP_CWORD]}\") )
  }
  complete -F #{completion} #{@program}
fi
### #{@program} completion - end ###
"
    end

  end
end

class Session
  attr_accessor :pbx
  attr_accessor :commands
  attr_accessor :application
  attr_accessor :channel
  attr_accessor :call_log

  def initialize(options = {})
    @vars = {}
    @log_level = :trace
    @js = new_v8_context

    options.each do |key, value|
      send "#{key}=", value
    end
  end

  def id
    @call_log.id
  end

  def []=(key, value)
    @vars[key] = value
    @js[key.to_s] = value
  end

  def [](key)
    @vars[key]
  end

  def delete(key)
    @vars.delete key
    @js[key.to_s] = nil
  end

  def eval(expr)
    @js.eval expr.to_s
  end

  def callback_url
    application.callback_url
  end

  def run
    raise "Answering machine detected" if @call_log && @call_log.outgoing? && @pbx.is_answering_machine?

    run_command until @commands.empty?
  rescue Exception => ex
    error ex.message
    @call_log.finish :failed if @call_log
  else
    @call_log.finish :completed if @call_log
  ensure
    # @pbx.interface.notify_call_queued @channel.id
  end

  def quit!
    @quit = true
  end

  def push_commands(commands)
    @commands.unshift *commands
  end

  [:info, :error, :trace].each do |name|
    class_eval %Q(
      def #{name}(text)
        @call_log.#{name} text if @call_log
      end
    )
  end

  def log(options)
    return unless @call_log

    if @log_level == :trace
      @call_log.trace options[:trace]
    else
      @call_log.info options[:info]
    end
  end

  def run_command
    raise "Quit" if @quit

    cmd = @commands.shift

    if cmd.is_a? Hash
      cmd, args = cmd.first
      args.symbolize_keys! if args.is_a? Hash

      cmd = "#{cmd.to_s.camelcase}Command".constantize.new args
    elsif !cmd.respond_to?(:run)
      cmd = "#{cmd.to_s.camelcase}Command".constantize.new
    end

    cmd.run self
  end

  def new_v8_context
    ctx = V8::Context.new
    ['digits', 'timeout', 'finish_key'].each { |key| ctx[key] = nil }
    ['answer', 'assign', 'callback', 'capture', 'hangup', 'js', 'play', 'record', 'say'].each do |func|
      ctx[func] = lambda do |*options|
        if options.length == 1 && options[0].respond_to?(:to_hash)
          options[0] = options[0].to_hash
          options[0].symbolize_keys!
        end
        "#{func.camelcase}Command".constantize.new(*options).run self
      end
    end
    ctx['alert'] = lambda { |str| info str }
    ctx
  end
end

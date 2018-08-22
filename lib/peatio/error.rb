class Peatio::Error < ::StandardError
  @@default_code = 2000

  attr :code, :text

  def initialize(opts = {})
    @code = opts[:code] || @@default_code
    @text = opts[:text] || ""

    @message = {error: {code: @code, message: @text}}

    if @text != ""
      super("#{@code}: #{text}")
    else
      super("#{@code}")
    end
  end
end

class SayCommand < PlayCommand
  param :text, :string, :ui_length => 80

  def initialize(text)
    super "http://translate.google.com/translate_tts?tl=en&q=#{CGI.escape text}"
  end
end
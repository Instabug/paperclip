module Paperclip
  class ContentTypeDetector
    EMPTY_TYPE = "inode/x-empty"
    SENSIBLE_DEFAULT = "application/octet-stream"

    def initialize(filename)
      @filename = filename
    end

    # Returns a String describing the file's content type
    def detect
      if blank_name?
        SENSIBLE_DEFAULT
      elsif empty_file?
        EMPTY_TYPE
      else
        type_from_file_command || SENSIBLE_DEFAULT
      end.to_s
    end

    private

    def empty_file?
      File.exist?(@filename) && File.size(@filename) == 0
    end

    alias :empty? :empty_file?

    def blank_name?
      @filename.nil? || @filename.empty?
    end

    def type_from_file_command
      @type_from_file_command ||=
        FileCommandContentTypeDetector.new(@filename).detect
    end
  end
end

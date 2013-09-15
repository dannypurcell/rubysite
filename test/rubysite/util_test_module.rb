require "#{File.expand_path(File.dirname(__FILE__))}/../../lib/rubysite.rb"
# A command module used for testing
module UtilTestModule

  # A test non-command method
  def non_command
    puts 'fail'
  end

  # A basic test command
  def self.test_command
    puts 'command test'
  end

  def self.test_command_no_docs
    puts 'no docs command test'
  end

  # A test_command with one arg
  #
  # @param [String] test_arg a test argument
  def self.test_command_with_arg(test_arg)
    "test_arg=#{test_arg}"
  end

  # A test_command with an arg named arg
  #
  # @param arg [String] a test argument whose parameter name is arg
  def self.test_command_arg_named_arg(arg)
    "arg=#{arg}"
  end

  # A test_command with two args
  # @param [String] test_arg a test argument
  # @param [String] another_test_arg another test argument
  def self.test_command_with_args(test_arg, another_test_arg)
    puts "test_arg=#{test_arg},another_test_arg=#{another_test_arg}"
  end

  # A test_command with an optional argument
  # @param test_arg [String] a test argument
  # @param [String] test_option an optional test argument
  def self.test_command_with_options(test_arg, test_option='option_default')
    puts "test_arg=#{test_arg},test_option=#{test_option}"
  end

  # A test_command with all optional arguments
  # @param [String] test_arg an optional test argument
  # @param [String] test_option another optional test argument
  def self.test_command_all_options(test_arg='test_arg_default', test_option='test_option_default')
    puts "Output is test_arg=#{test_arg},test_option=#{test_option}"
  end

  # A test_command with an options array
  # @param [String] test_option an optional test argument
  # @param [Array] test_options an optional array of arguments
  def self.test_command_options_arr (
      test_option="test_option_default",
          *test_options
  )
    puts "Output is test_option=#{test_option},test_option_arr=#{test_options}"
  end

  # A test_command with a return argument
  #
  # @param [String] test_arg a test argument
  # @param test_option_int [Integer] an optional test argument which happens to be an Integer
  # @return [Array] an array including both params if test_option_int != 1
  # @return [String] a the first param if test_option_int == 1
  def self.test_command_with_return(test_arg, test_option_int=1)
    ret = [test_arg, test_option_int]
    if test_option_int == 1
      ret = test_arg
    end
    ret
  end

  # A test_command with a Timestamp argument and an unnecessarily long description which should overflow when
  # it tries to line up with other descriptions.
  # @param [Timestamp] test_time a test Timestamp argument
  # @return [Hash] a hash including the given argument
  def self.test_command_arg_timestamp(test_time)
    {test_time: test_time}
  end

  # A test_command with a Boolean argument
  # @param test_flag [Boolean] a test Boolean argument
  # @return [Boolean] the flag passed in
  def self.test_command_arg_false(test_flag=false)
    test_flag
  end

  # A test_command with an array argument
  #
  # @param [Array] test_arr an Array test argument
  def self.test_command_arg_arr(test_arr=[])
    "test_arr is #{test_arr} \n test_arr.class is #{test_arr.class}"
  end

  # A test_command with an Hash argument
  # @param [Hash] test_hash a Hash test argument
  def self.test_command_arg_hash(test_hash={})
    "test_hash is #{test_hash} \n test_hash.class is #{test_hash.class}"
  end

  # A test_command with several mixed options
  def self.test_command_mixed_options(test_arg, test_arr=[], test_opt='test_opt_arg', test_hsh={}, test_bool=true, *test_rest)
    "test_arg=#{test_arg} test_arr=#{test_arr} test_opt=#{test_opt} test_hsh=#{test_hsh} test_bool=#{test_bool} test_rest=#{test_rest}"
  end

  # A test_command with an Textarea argument
  # @param [Textarea] test_textarea a test argument documented as a Textarea field
  def self.test_command_textarea_arg(test_textarea)
    "test_textarea is #{test_textarea} \n test_textarea.class is #{test_textarea.class}"
  end

    # A test_command with an Number argument
  # @param [Number] test_number a test argument documented as a Number field
  def self.test_command_number_arg(test_number)
    "test_number is #{test_number} \n test_number.class is #{test_number.class}"
  end

  # A test_command with an Range argument
  # @param [Range] test_range a test argument documented as a Range field
  def self.test_command_range_arg(test_range)
    "test_range is #{test_range} \n test_range.class is #{test_range.class}"
  end

  # A test_command with an Tel argument
  # @param [Tel] test_tel a test argument documented as a Tel field
  def self.test_command_tel_arg(test_tel)
    "test_tel is #{test_tel} \n test_tel.class is #{test_tel.class}"
  end

  # A test_command with an Checkbox argument
  # @param [Checkbox] test_checkbox a test argument documented as a Checkbox field
  def self.test_command_checkbox_arg(test_checkbox)
    "test_checkbox is #{test_checkbox} \n test_checkbox.class is #{test_checkbox.class}"
  end

  # A test_command with an Url argument
  # @param [Url] test_url a test argument documented as a Url field
  def self.test_command_url_arg(test_url)
    "test_url is #{test_url} \n test_url.class is #{test_url.class}"
  end

  # A test_command with an Email argument
  # @param [Email] test_email a test argument documented as a Email field
  def self.test_command_email_arg(test_email)
    "test_email is #{test_email} \n test_email.class is #{test_email.class}"
  end

  # A test_command with an File argument
  # @param [File] test_file a test argument documented as a File field
  def self.test_command_file_arg(test_file)
    "test_file is #{test_file} \n test_file.class is #{test_file.class}"
  end

  # A test_command with an Image argument
  # @param [Image] test_image a test argument documented as a Image field
  def self.test_command_image_arg(test_image)
    "test_image is #{test_image} \n test_image.class is #{test_image.class}"
  end

  # A test_command with an Color argument
  # @param [Color] test_color a test argument documented as a Color field
  def self.test_command_color_arg(test_color)
    "test_color is #{test_color} \n test_color.class is #{test_color.class}"
  end

  # A test_command with an Password argument
  # @param [Password] test_password a test argument documented as a Password field
  def self.test_command_password_arg(test_password)
    "test_password is #{test_password} \n test_password.class is #{test_password.class}"
  end

  # A test_command with an Date argument
  # @param [Date] test_date a test argument documented as a Date field
  def self.test_command_date_arg(test_date)
    "test_date is #{test_date} \n test_date.class is #{test_date.class}"
  end

  # A test_command with an Datetime argument
  # @param [Datetime] test_datetime a test argument documented as a Datetime field
  def self.test_command_datetime_arg(test_datetime)
    "test_datetime is #{test_datetime} \n test_datetime.class is #{test_datetime.class}"
  end

  # A test_command with an Datetime-local argument
  # @param [Datetime-local] test_datetime_local a test argument documented as a Datetime-local field
  def self.test_command_datetime_local_arg(test_datetime_local)
    "test_datetime_local is #{test_datetime_local} \n test_datetime_local.class is #{test_datetime_local.class}"
  end

  # A test_command with an Month argument
  # @param [Month] test_month a test argument documented as a Month field
  def self.test_command_month_arg(test_month)
    "test_month is #{test_month} \n test_month.class is #{test_month.class}"
  end

  # A test_command with an Week argument
  # @param [Week] test_week a test argument documented as a Week field
  def self.test_command_week_arg(test_week)
    "test_week is #{test_week} \n test_week.class is #{test_week.class}"
  end

  # A test_command with an Time argument
  # @param [Time] test_time a test argument documented as a Time field
  def self.test_command_time_arg(test_time)
    "test_time is #{test_time} \n test_time.class is #{test_time.class}"
  end

  # Guaranteed to raise an error every time
  # @param test_msg a message to be printed to stdout
  def self.test_command_exception(test_msg)
    puts test_msg
    raise "Check out this error!"
  end

  include Rubysite
end
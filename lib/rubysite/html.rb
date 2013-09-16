module Rubysite
  module Html

    # Generates HTML form input tags and accompanying markup for each field hash in the given array.
    #
    # @param form_fields [Array] an Array of Hashes. Required Keys - :name, :type Optional keys - :value, :label, :doc
    # @return [String] Html snippet representing the form controls for the given fields
    def self.generate_fields(form_fields)
      raise 'form_fields must be an Array' if form_fields.class != Array
      form_fields.each { |field|
        raise "form_fields entry #{field} must be a Hash" if field.class != Hash
        [:name, :type].each { |req_key|
          raise "form_fields entry #{field} must respond to #{req_key}" if !field.has_key?(req_key)
        }
      }

      form_fields.map { |field|
        self.gen_field(self.get_html_type(field[:type]), field[:name], field[:label], field[:value], field[:doc])
      }.join("<br />\n")
    end

    def self.get_html_type(documented_type)
      type = documented_type.to_s.downcase
      return 'text' if ['string'].include?(type)
      return 'textarea' if ['text'].include?(type)
      return 'number' if ['integer', 'fixnum'].include?(type)
      return 'range' if ['range'].include?(type)
      return 'tel' if ['tel', 'telephone', 'phone-number'].include?(type)
      return 'checkbox' if ['boolean'].include?(type)
      return 'url' if ['url'].include?(type)
      return 'email' if ['email'].include?(type)
      return 'file' if ['file', 'path'].include?(type)
      return 'color' if ['color'].include?(type)
      return 'password' if ['password'].include?(type)
      return 'date' if ['date'].include?(type)
      return 'datetime' if ['datetime '].include?(type)
      return 'datetime-local' if ['datetime-local'].include?(type)
      return 'month' if ['month'].include?(type)
      return 'week' if ['week'].include?(type)
      return 'time' if ['time', 'timestamp'].include?(type)
      return documented_type
    end

    def self.gen_field(type, name, label, value, help_doc)
      $stdout.sync = true
      case type.downcase
        when 'array', 'rest'
          self.gen_dynamic_text(name, label, value, help_doc)
        when 'text'
          self.gen_text(name, label, value, help_doc)
        when 'textarea'
          self.gen_textarea(name, label, value, help_doc)
        when 'number'
          self.gen_number(name, label, value, help_doc)
        when 'checkbox'
          self.gen_checkbox(name, label, value, help_doc)
        when 'file'
          self.gen_file(name, label, value, help_doc)
        when 'date'
          self.gen_date(name, label, value, help_doc)
        else
          self.gen_default(name, label, value, help_doc, type)
      end
    end

    def self.get_placeholder(value)
      (value == :nil_rubycom_required_param) ? "required" : "placeholder='#{value}'"
    end

    def self.gen_default(name, label, value, help_doc, original_type)
      <<-END.gsub(/^ {6}/, '')
      <div class='control-group'>
        <label class='control-label' for='#{name}'>#{label}</label>
        <div class='controls'>
          <input id='#{name}' name='#{name}' type='#{original_type}' class='input-xlarge' #{self.get_placeholder(value)} />
          <p class='help-block'>#{help_doc}</p>
          <p class='help-block'>Documented field type: #{original_type}</p>
        </div>
      </div>
      END
    end

    def self.gen_text(name, label, value, help_doc)
      <<-END.gsub(/^ {6}/, '')
      <div class='control-group'>
        <label class='control-label' for='#{name}'>#{label}</label>
        <div class='controls'>
          <input id='#{name}' name='#{name}' type='text' class='input-xlarge' #{self.get_placeholder(value)} />
          <p class='help-block'>#{help_doc}</p>
        </div>
      </div>
      END
    end

    def self.gen_dynamic_text(name, label, value, help_doc)
      <<-END.gsub(/^ {6}/, '')
      <div class='control-group'>
        <label class='control-label' for='#{name}0'>#{label}</label>
        <div class='controls'>
          <div class="input-append">
            <input id='#{name}0' name='#{name}[]' type='text' class='input-xlarge' #{self.get_placeholder(value)} />
            <button id="b1" onClick="add#{name}Field()" class="btn btn-info" type="button">+</button>
          </div>
          <p class='help-block'>#{help_doc}</p>
          <small>Press + to add another</small>
        </div>
      </div>
      <script type="text/javascript">
        var next = 0;
        function add#{name}Field(){
          console.log('call: add#{name}Field(), next='+next)
          var addTo = "##{name}" + next;
          next = next + 1;
            var newIn = '<br /><br /><input id="#{name}'+next+'" name="#{name}[]" type="text" class="input-xlarge" />';
            var newInput = $(newIn);
          $(addTo).after(newInput);
        }
      </script>
      END
    end

    def self.gen_dynamic_key_value_text(name, label, value, help_doc)
      <<-END.gsub(/^ {6}/, '')
      <div class='control-group'>
        <label class='control-label' for='#{name}0'>#{label}</label>
        <div class='controls'>
          <div class="input-append">
            <input id='#{name}0' name='#{name}[]' type='text' class='input-xlarge' #{self.get_placeholder(value)} />
            <button id="b1" onClick="add#{name}Field()" class="btn btn-info" type="button">+</button>
          </div>
          <p class='help-block'>#{help_doc}</p>
          <small>Press + to add another</small>
        </div>
      </div>
      <script type="text/javascript">
        var next = 0;
        function add#{name}Field(){
          console.log('call: add#{name}Field(), next='+next)
          var addTo = "##{name}" + next;
          next = next + 1;
            var newIn = '<br /><br /><input id="#{name}'+next+'" name="#{name}[]" type="text" class="input-xlarge" />';
            var newInput = $(newIn);
          $(addTo).after(newInput);
        }
      </script>
      END
    end

    def self.gen_textarea(name, label, value, help_doc)
      placeholder = self.get_placeholder(value)
      <<-END.gsub(/^ {6}/, '')
      <div class='control-group'>
        <label class='control-label' for='#{name}'>#{label}</label>
        <div class='input controls'>
          <textarea id='#{name}' name='#{name}' class='xxlarge span4' rows="6" #{placeholder if placeholder == 'required' }>#{placeholder unless placeholder == 'required' }</textarea>
          <p class='help-block'>#{help_doc}</p>
        </div>
      </div>
      END
    end

    def self.gen_number(name, label, value, help_doc)
      <<-END.gsub(/^ {6}/, '')
      <div class='control-group'>
        <label class='control-label' for='#{name}'>#{label}</label>
        <div class='controls'>
          <input id='#{name}' name='#{name}' type='number' class='input-xlarge' #{self.get_placeholder(value)} />
          <p class='help-block'>#{help_doc}</p>
        </div>
      </div>
      END
    end

    def self.gen_checkbox(name, label, value, help_doc)
      <<-END.gsub(/^ {6}/, '')
      <div class='control-group'>
        <label class='control-label' for='#{name}'>#{label}</label>
        <div class='controls'>
          <input id='#{name}' name='#{name}' type='checkbox' class='input-xlarge' #{"checked" if value} />
          <p class='help-block'>#{help_doc}</p>
        </div>
      </div>
      END
    end

    def self.gen_file(name, label, value, help_doc)
      <<-END.gsub(/^ {6}/, '')
      <div class='control-group'>
        <label class='control-label' for='#{name}'>#{label}</label>
        <div class='controls'>
          <input id='#{name}' name='#{name}' type='file' class='input-xlarge' #{self.get_placeholder(value)} />
          <p class='help-block'>#{help_doc}</p>
        </div>
      </div>
      END
    end

    def self.gen_date(name, label, value, help_doc)
      <<-END.gsub(/^ {6}/, '')
      <div class='control-group'>
        <label class='control-label' for='#{name}'>#{label}</label>
        <div class='controls'>
          <input id='#{name}' name='#{name}' type='date' class='input-xlarge' #{self.get_placeholder(value)} />
          <p class='help-block'>#{help_doc}</p>
        </div>
      </div>
      END
    end

  end

end
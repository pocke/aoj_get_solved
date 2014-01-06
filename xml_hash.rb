require 'rexml/document'

class ::REXML::Document
  def to_hash
    self.root.to_hash
  end
end

class ::REXML::Element
  def to_hash
    value =
      if self.has_elements? then
        children = {}
        self.each_element do |e|
          children.merge!(e.to_hash) do |k, v1, v2|
            v1.is_a?(Array) ? v1 << v2 : [v1, v2]
          end
        end
        children
      else
        self.text
      end
    {self.name.to_sym => value}
  end
end

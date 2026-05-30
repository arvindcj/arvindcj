# Compatibility for Liquid 4 on Ruby 4, where Object#tainted? was removed.
class Object
  def tainted?
    false
  end unless method_defined?(:tainted?)
end

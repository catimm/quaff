require_relative '../core_extensions/object'

module SparkPost
  module Helpers
    def copy_value(src_hash, src_key, dst_hash, dst_key)
      dst_hash[dst_key] = src_hash[src_key] if src_hash.key?(src_key)
    end

    def deep_merge(source_hash, other_hash)
      source_hash.merge(other_hash) do |_key, oldval, newval|
        if newval.respond_to?(:blank?) && newval.blank?
          oldval
        elsif oldval.is_a?(Hash) && newval.is_a?(Hash)
          deep_merge(oldval, newval)
        else
          newval
        end
      end
    end

    module_function :copy_value, :deep_merge
  end
end

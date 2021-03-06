module Sprig::Reap
  class Model
    def self.all
      @@all ||= begin
        models = Sprig::Reap.classes.map { |klass| new(klass) }
        
        tsorted_classes(models).map do |klass|
          models.find { |model| model.klass == klass }
        end
      end
    end

    def self.find(klass, id)
      all.find { |model| model.klass == klass }.find(id)
    end

    attr_reader :klass
    attr_writer :existing_sprig_ids

    def initialize(klass)
      @klass = klass
    end

    def attributes
      klass.column_names - Sprig::Reap.ignored_attrs
    end

    def dependencies
      @dependencies ||= klass.reflect_on_all_associations(:belongs_to).map do |association|
        association.name.to_s.classify.constantize
      end
    end

    def existing_sprig_ids
      @existing_sprig_ids ||= []
    end

    def generate_sprig_id
      existing_sprig_ids.select { |i| i.is_a? Integer }.sort.last + 1
    end

    def find(id)
      records.find { |record| record.id == id }
    end

    def to_s
      klass.to_s
    end

    def to_yaml(options = {})
      namespace         = options[:namespace]
      formatted_records = records.map(&:to_hash)

      yaml = if namespace
        { namespace => formatted_records }.to_yaml
      else
        formatted_records.to_yaml
      end

      yaml.gsub("---\n", '') # Remove annoying YAML separator
    end

    def records
      @records ||= klass.all.map { |record| Record.new(record, self) }
    end

    private

    def self.tsorted_classes(models)
      models.reduce(TsortableHash.new) do |hash, model|
        hash.merge(model.klass => model.dependencies)
      end.tsort
    end
  end
end

module Ask
  module Skills
    module Source
      class Base
        def load
          raise NotImplementedError
        end

        def name
          raise NotImplementedError
        end
      end
    end
  end
end

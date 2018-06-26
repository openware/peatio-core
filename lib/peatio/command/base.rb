module Peatio::Command

    class Base < Clamp::Command

        def say(str)
            puts str
        end
    end
end

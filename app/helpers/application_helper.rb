# app/helpers/application_helper.rb
module ApplicationHelper
	def flash_class(type)
		case type.to_sym
		when :notice
			"bg-green-50 text-green-800 border border-green-200"
		when :alert
			"bg-red-50 text-red-800 border border-red-200"
		when :error
			"bg-red-50 text-red-800 border border-red-200"
		else
			"bg-blue-50 text-blue-800 border border-blue-200"
		end
	end
end

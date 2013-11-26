class Link < ActiveRecord::Base
	belongs_to :gathering, class_name: "Gather"
	belongs_to :invitation
	validates :in_url, :out_url, :http_status, :presence => true
	validates :in_url, :uniqueness => true
end

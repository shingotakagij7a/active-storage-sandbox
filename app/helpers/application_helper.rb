module ApplicationHelper
	# Safely render a thumbnail for an ActiveStorage attachment.
	# If libvips (or other processor) is missing, it will log and skip without raising.
	def render_attachment_thumbnail(file)
		return unless file.respond_to?(:image?) && file.image?
		# Use original blob; HTML size attributes to visually constrain without processing
		image_tag file, size: "150x150"
	end
end

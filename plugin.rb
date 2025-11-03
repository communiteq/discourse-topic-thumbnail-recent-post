# frozen_string_literal: true

# name: discourse-topic-thumbnail-recent-post
# about: Set topic thumbnail to most recently updated post of topic starter
# version: 1.2
# authors: Communiteq
# url: https://github.com/communiteq/discourse-topic-thumbnail-recent-post

enabled_site_setting :topic_thumbnail_recent_post_enabled

after_initialize do
  Category.register_custom_field_type("enable_thumbnail_recent_post", :boolean)
  Site.preloaded_category_custom_fields << "enable_thumbnail_recent_post"

  DiscourseEvent.on(:post_process_cooked) do |doc, post|
    if SiteSetting.topic_thumbnail_recent_post_enabled?
      if post.topic && post.topic&.user&.id == post&.user&.id && post.image_upload_id && post.topic.category && post.topic.category.custom_fields[:enable_thumbnail_recent_post]
        upload = post.image_upload

        # Skip GIF files - they are excluded from being used as topic thumbnails
        # Upload does not expose a `content_type` attribute; use `extension` (and fallback to filename)
        if upload && (upload.extension&.downcase == "gif" || upload.original_filename&.downcase&.end_with?(".gif"))
          next
        end

        post.topic.image_upload_id = post.image_upload_id
        post.topic.save!
      end
    end
  end
end

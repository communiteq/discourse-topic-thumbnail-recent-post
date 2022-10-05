# frozen_string_literal: true

# name: discourse-topic-thumbnail-recent-post
# about: Set topic thumbnail to most recent post of topic starter
# version: 1.0
# authors: Communiteq
# url: https://github.com/communiteq/discourse-topic-thumbnail-recent-post

enabled_site_setting :topic_thumbnail_recent_post_enabled

after_initialize do
  DiscourseEvent.on(:post_process_cooked) do |doc, post|
    if SiteSetting.topic_thumbnail_recent_post_enabled? 
      if post.topic && post.topic&.user&.id == post&.user&.id && post.image_upload_id
        post.topic.image_upload_id = post.image_upload_id
        post.topic.save!
      end
    end
  end
end

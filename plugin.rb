# frozen_string_literal: true

# name: discourse-topic-thumbnail-recent-post
# about: Set topic thumbnail to most recent journal entry of topic starter
# version: 1.1
# authors: Communiteq
# url: https://github.com/communiteq/discourse-topic-thumbnail-recent-post

enabled_site_setting :topic_thumbnail_recent_post_enabled

after_initialize do
  DiscourseEvent.on(:post_process_cooked) do |doc, post|
    if SiteSetting.topic_thumbnail_recent_post_enabled? 
      # the post must be a journal and it must be an entry
      if post.topic && post.topic&.user&.id == post&.user&.id && post.image_upload_id && post.respond_to?(:journal?) && post.journal? && post.entry?
        post.topic.image_upload_id = post.image_upload_id
        post.topic.save!
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe "discourse-topic-thumbnail-recent-post" do
  fab!(:user) { Fabricate(:user) }
  fab!(:category) { Fabricate(:category) }
  
  let(:topic) { Fabricate(:topic, user: user, category: category) }
  let(:post) { Fabricate(:post, topic: topic, user: user) }
  
  before do
    SiteSetting.topic_thumbnail_recent_post_enabled = true
    category.custom_fields[:enable_thumbnail_recent_post] = true
    category.save!
  end
  
  describe "GIF exclusion" do
    let(:gif_upload) do
      Fabricate(:upload, 
        user: user,
        content_type: "image/gif",
        extension: "gif",
        width: 100,
        height: 100
      )
    end
    
    let(:jpg_upload) do
      Fabricate(:upload,
        user: user,
        content_type: "image/jpeg",
        extension: "jpg",
        width: 100,
        height: 100
      )
    end
    
    let(:png_upload) do
      Fabricate(:upload,
        user: user,
        content_type: "image/png",
        extension: "png",
        width: 100,
        height: 100
      )
    end
    
    it "updates topic thumbnail when post has a non-GIF image (JPEG)" do
      post.image_upload_id = jpg_upload.id
      post.save!
      
      DiscourseEvent.trigger(:post_process_cooked, nil, post)
      
      expect(topic.reload.image_upload_id).to eq(jpg_upload.id)
    end
    
    it "updates topic thumbnail when post has a non-GIF image (PNG)" do
      post.image_upload_id = png_upload.id
      post.save!
      
      DiscourseEvent.trigger(:post_process_cooked, nil, post)
      
      expect(topic.reload.image_upload_id).to eq(png_upload.id)
    end
    
    it "does not update topic thumbnail when post has a GIF image" do
      # Set an initial thumbnail
      topic.image_upload_id = jpg_upload.id
      topic.save!
      
      # Try to update with a GIF
      post.image_upload_id = gif_upload.id
      post.save!
      
      DiscourseEvent.trigger(:post_process_cooked, nil, post)
      
      # Should still have the original thumbnail, not the GIF
      expect(topic.reload.image_upload_id).to eq(jpg_upload.id)
    end
    
    it "does not set topic thumbnail when first image is a GIF" do
      post.image_upload_id = gif_upload.id
      post.save!
      
      DiscourseEvent.trigger(:post_process_cooked, nil, post)
      
      expect(topic.reload.image_upload_id).to be_nil
    end
    
    it "excludes GIF based on content_type even if extension is missing" do
      gif_no_ext = Fabricate(:upload,
        user: user,
        content_type: "image/gif",
        extension: nil,
        width: 100,
        height: 100
      )
      
      topic.image_upload_id = jpg_upload.id
      topic.save!
      
      post.image_upload_id = gif_no_ext.id
      post.save!
      
      DiscourseEvent.trigger(:post_process_cooked, nil, post)
      
      expect(topic.reload.image_upload_id).to eq(jpg_upload.id)
    end
    
    it "excludes GIF based on extension even if content_type is wrong" do
      gif_wrong_type = Fabricate(:upload,
        user: user,
        content_type: "image/jpeg", # Wrong content type
        extension: "gif", # But extension is gif
        width: 100,
        height: 100
      )
      
      topic.image_upload_id = jpg_upload.id
      topic.save!
      
      post.image_upload_id = gif_wrong_type.id
      post.save!
      
      DiscourseEvent.trigger(:post_process_cooked, nil, post)
      
      expect(topic.reload.image_upload_id).to eq(jpg_upload.id)
    end
  end
  
  describe "plugin behavior" do
    let(:jpg_upload) do
      Fabricate(:upload,
        user: user,
        content_type: "image/jpeg",
        extension: "jpg",
        width: 100,
        height: 100
      )
    end
    
    it "does not update when site setting is disabled" do
      SiteSetting.topic_thumbnail_recent_post_enabled = false
      
      post.image_upload_id = jpg_upload.id
      post.save!
      
      DiscourseEvent.trigger(:post_process_cooked, nil, post)
      
      expect(topic.reload.image_upload_id).to be_nil
    end
    
    it "does not update when category custom field is disabled" do
      category.custom_fields[:enable_thumbnail_recent_post] = false
      category.save!
      
      post.image_upload_id = jpg_upload.id
      post.save!
      
      DiscourseEvent.trigger(:post_process_cooked, nil, post)
      
      expect(topic.reload.image_upload_id).to be_nil
    end
    
    it "does not update when post author is not the topic starter" do
      other_user = Fabricate(:user)
      other_post = Fabricate(:post, topic: topic, user: other_user)
      other_post.image_upload_id = jpg_upload.id
      other_post.save!
      
      DiscourseEvent.trigger(:post_process_cooked, nil, other_post)
      
      expect(topic.reload.image_upload_id).to be_nil
    end
    
    it "does not update when post has no image" do
      DiscourseEvent.trigger(:post_process_cooked, nil, post)
      
      expect(topic.reload.image_upload_id).to be_nil
    end
    
    it "does not update when topic has no category" do
      topic_no_category = Fabricate(:topic, user: user, category: nil)
      post_no_category = Fabricate(:post, topic: topic_no_category, user: user)
      post_no_category.image_upload_id = jpg_upload.id
      post_no_category.save!
      
      DiscourseEvent.trigger(:post_process_cooked, nil, post_no_category)
      
      expect(topic_no_category.reload.image_upload_id).to be_nil
    end
  end
end


require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  test "should create comment and redirect to post without javascript" do
    p = Post.create!(:title => 'hello', :body => 'world')
    post :create, :post_id => p.id, :comment => { :body => 'nice!' }
    assert_redirected_to post_url(p)
    assert_equal 'nice!', p.comments.first.body
  end

  test "should create comment and render RJS template for ajax" do
    p = Post.create!(:title => 'hello', :body => 'world')
    post :create, :format => 'js', :post_id => p.id, :comment => { :body => 'nice!' }
    assert_template 'create.js.rjs'
    assert_equal 'nice!', p.comments.first.body
  end
end

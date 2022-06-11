class PostsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post_contest, only: %i[show destroy edit update review_complete review_incomplete]
  PER_PAGE = 10

  def index
    @q = current_user.posts.includes(:contest, :tags).ransack(params[:q])
    @posts = @q.result.page(params[:page]).per(PER_PAGE)
  end

  def new
    @contest = Contest.new
    @post = @contest.posts.new
    @tag = @post.tags.pluck(:name).join(" ")
  end

  def create
    @contest = Contest.new(contest_params)
    unless @contest.save
      flash.now[:alert] = "投稿に失敗しました"
      render :new
    end
    @post = current_user.posts.new(post_params)
    @post.contest_id = @contest.id
    tag_list = params[:post][:name].split(" ")
    if @post.correct == "AC"
      @post.review_completion = 1
      @post.review_date = Time.current
    end
    if @post.save
      @post.save_tag(tag_list)
      redirect_to @post, notice: "投稿しました"
    else
      flash.now[:alert] = "投稿に失敗しました"
      render :new
    end
  end

  def show
    @post_tags = @post.tags
  end

  def destroy
    post_tag_id = @post.tags.pluck(:tag_id)
    @post.destroy!
    post_tag_id.each do |number|
      Tag.find_by(id: number).delete if PostTag.where(tag_id: number).count.zero?
    end
    @post.destroy!
    redirect_to posts_path, alert: "削除しました"
  end

  def edit
    @tag = @post.tags.pluck(:name).join(" ")
  end

  def update
    tag_list = params[:post][:name].split(" ")
    if @post.correct == "AC"
      @post.review_completion = 1
      @post.review_date = Time.current
    end
    if @post.update(post_params) && @contest.update(contest_params)
      @post.save_tag(tag_list)
      if @old_tags.present?
        @old_tags.each do |tag|
          Tag.find_by(id: tag.id).delete if PostTag.where(tag_id: tag.id).count.zero?
        end
      end
      redirect_to @post, notice: "更新しました"
    else
      flash.now[:alert] = "更新に失敗しました"
      render :edit
    end
  end

  def search
    @q = current_user.posts.includes(:contest, :tags).ransack(search_params)
    @posts = @q.result.page(params[:page]).per(PER_PAGE)
  end

  def search_tag
    @tag_list = Tag.all
    @tag = Tag.find(params[:id])
    @posts = @tag.posts.includes(:contest, :tags).page(params[:page]).per(PER_PAGE)
  end

  def review_complete
    @post.review_date = Time.current
    @post.review_completion = 1
    @post.save
    redirect_back(fallback_location: posts_path)
  end

  def review_incomplete
    @post.review_completion = 0
    @post.save
    redirect_back(fallback_location: posts_path)
  end

  private

  def search_params
    params.require(:q).permit!
  end

  def set_post_contest
    @post = Post.find(params[:id])
    @contest = Contest.find(@post.contest_id)
  end

  def post_params
    params.require(:post).permit(:question_name, :code, :comment, :correct, :contest_id, :image)
  end

  def contest_params
    params.require(:post).permit(:contest_name, :contest_number)
  end
end

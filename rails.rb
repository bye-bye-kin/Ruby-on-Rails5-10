
いいね機能をつける

「どのユーザー」が「どの投稿」をいいねしたかを記録する。


#Likeモデルとマイグレーションファイルを用意しましょう。
#user_idが1、post_idが2のデータは、「id:1のユーザーがid:2の投稿をいいねした」ということを表します。
#マイグレーションファイルの用意ができたら「rails db:migrate」を実行して、データベースに反映させましょう。

rails g model Like user_id:integer post_id:integer

rails db:migrate


#いいねのデータは、user_idとpost_idの両方が常に存在していないと不完全なデータとなってしまいますので、
#最初にバリデーションを追加しておきましょう。user_idとpost_idのそれぞれに、値が存在していることをチェックする
#「presence: true」のバリデーションを追加します。
#/models/like.rb
class Like < ApplicationRecord
    validates :user_id, {presence: true}
    validates :post_id, {presence: true}
  end

#####################################################################################################################

コンソールでlikesテーブルにデータを追加してみましょう。
「Like.new(user_id: 1, post_id: 2)」とすることで、「idが1のユーザーが、idが2の投稿にいいねした」
というデータを作成することができます。

#rails consoleで以下のコマンドを実行してください
like = Like.new(user_id: 1, post_id: 2)
like.save
quit

####################################################################################################################

投稿詳細ページでは、「ログインしているユーザーがその投稿にいいねしたデータが存在する」という条件を満たす場合、
「いいね！済み」と表示するようにしましょう。
逆に、この条件を満たしていない場合には「いいね！していません」と表示しましょう。
条件分岐　find_byを用いる。特定のデータが欲しいからfind_byを使う！そうじゃなかったらwhere使うよ

#<% if Like.find_by(user_id: @current_user.id, post_id: @post.id)%> ←この２つの条件を満たすデータがlikeテーブルにあるかどうか。
#        いいね！済み
#        <%else%>
#          いいね！していません
#       <%end%>

###################################################################################################################

いいねボタンを作りたい

今までコントローラは「rails g controller」コマンドで自動生成してきました。
コマンドを用いるとビューファイルなども自動生成されますが、今回はそれらのビューファイルが必要ないので、
コントローラを手動で作ってみましょう。controllersフォルダ内に「likes_controller.rb」というファイルを新規作成し、
右の図のように大枠を記述するだけで作ることができます。
#ルーティング
#post URL => コントローラ名#アクション名
post "likes/:post_id/create" => "likes#create"

#/controllers/likes_controller.rb
class LikesController < ApplicationController
    before_action :authenticate_user
    
    def create
    end
    
  end

######################################################################################################################

createアクションの中身を完成させましょう。 
createアクション内では新たにデータを作成後、投稿詳細ページへとリダイレクトさせます。 
user_idは@current_userから、post_idはparamsから取得して作成しましょう。

作成したcreateアクションへのリンクを投稿詳細ページに追加しましょう。 
下の図のように、今までは「いいね！していません」と表示していた部分を、「いいね！」するためのリンクに書き換えます。

#/controllers/likes_controller.rb
def create
  @like = Like.new(
    user_id: @current_user.id,
    post_id: params[:post_id]
  )
  
  @like.save
  
  redirect_to("/posts/#{params[:post_id]}")

end

#/posts/show.html.erb
#<%=link_to("いいね！","/likes/#{@post.id}/create",{method:"post"})%>

###################################################################################################################

「いいね！」を取り消す
まずはlikesコントローラにdestroyアクションを作成しましょう。
destroyアクション内では、受け取った@current_user.idとparams[:post_id]をもとに削除すべきLikeデータを取得し、
destroyメソッドを用いて削除します。
#ルーティング
post "likes/:post_id/destroy" => "likes#destroy"
#controllers/likes_controller.rb
def destroy
  @like = Like.find_by(
    user_id: @current_user.id,
    post_id: params[:post_id]
    )
   @like.destroy
   redirect_to("/posts/#{params[:post_id]}")
   
end

作成したdestroyアクションへのリンクを投稿詳細ページに追加しましょう。 
下の図のように、今までは「いいね！済み」と表示していた部分を、「いいね！」を取り消すためのリンクに書き換えます。
#/posts/show.html.erb
#<!-- 以下の1行をdestroyアクションへのリンクに書き換えてください -->
#       <%= link_to("いいね！済み", "/likes/#{@post.id}/destroy", {method: "post"}")%>

#########################################################################################################################

いいねボタン作るよ

「Font Awesome」を利用するには、<head>タグ内で読み込みをする必要があります。
<head>タグなどの共通のHTMLはapplication.html.erbに書きますので、
今回はそこに読み込み用の<link>タグを追加しましょう。

<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css">

<span>に「fa fa-heart」というクラス名をつけることで、ハートアイコンを表示することができます。
しかし、link_toメソッド内にHTML要素を記述すると正しく表示することができません。

HTML要素に対してlink_toメソッドを使う方法
<%= link_to(URL) do %>と<% end %>の間にHTML要素を書くことで、その部分をリンクにすることができます。

  <%= link_to("/likes/#{@post.id}/create", {method: "post"}) do %>
  <span class="fa fa-heart like-btn"></span>
#  <%end%>

#######################################################################################################################

いいねの件数を取得する

likesテーブルからデータの件数を取得するには、countメソッドを用います。
countメソッドは配列の要素数を取得するメソッドですが、テーブルのデータ数を取得するためにも利用することができます。

#/controllers/posts_controller.rb
@likes_count=Like.where(post_id: @post.id).count


#/posts/show.html.erb
#<!-- 変数@likes_countを表示してください -->
#<%= @likes_count%>

###########################################################################################################################

「いいね！」をした投稿を一覧で表示する

likesアクションをusersコントローラ内に作成しましょう。 
ルーティングのURL部分はshowアクションと同様に、どのユーザーに関する情報を表示するかを判断するために
「users/:id/likes」とします。

#/config/routes.rb
「localhost:3000/users/:id/likes」というURLでアクセスできるルーティングを追加してください。
※ ただし、対応するアクションはusersコントローラのlikesアクションとなるようにしてください。
get "users/:id/likes" => "users#likes"


ビューで用いる変数をアクション内で定義しましょう。 
whereメソッドを用いてそのユーザーに関するデータをlikesテーブルから取得し、変数@likesに代入します。
#/controllers/users_controller.rb

def likes
  # 変数@userを定義してください
  @user=User.find_by(id: params[:id])
  
  # 変数@likesを定義してください
  
  @likes=Like.where(user_id: @user.id)
  
end

likesアクション内で定義した変数@userと@likesを用いて、ビューも完成させましょう。 
各投稿を1つずつ表示するためには、@likesに対してeach文を用いて、likeに紐付いているpostを表示させます。

<% @likes.each do |like| %>
<!-- 変数postを定義してください -->
<% post =Post.find_by(id: like.post_id)%>



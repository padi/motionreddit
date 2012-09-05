class RedditPost
  attr_accessor :title, :url, :author
  attr_accessor :comments, :score
  attr_accessor :subreddit

  def initialize(data)
    @url = data["url"]
    @title = data["title"]
    @author = data["author"]
    @comments = data["num_comments"]
    @link = data["permalink"]
    @score = data["score"]
    @subreddit = data["subreddit"]
  end
end

class RedditController < UITableViewController
  def viewDidLoad
    @posts = []
    view.dataSource = view.delegate = self
    refresh "top.json"
  end

  def tableView(tv, numberOfRowsInSection:section)
    @posts.size
  end

  def tableView(tv, cellForRowAtIndexPath:indexPath)
    cid = "PostCell"
    cell = tv.dequeueReusableCellWithIdentifier(cid) ||
           UITableViewCell.alloc.initWithStyle(
                UITableViewCellStyleSubtitle,
                reuseIdentifier:cid)

    p = @posts[indexPath.row]

    cell.textLabel.text = p.title
    cell.detailTextLabel.text = "Posted by #{p.author} in #{p.subreddit}"
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator

    cell
  end

  def tableView(tv, didSelectRowAtIndexPath:indexPath)
    url = NSURL.URLWithString @posts[indexPath.row].url
    UIApplication.sharedApplication.openURL url
    tv.deselectRowAtIndexPath(indexPath, animated:true)
  end

  def get(address)
    err = Pointer.new_with_type "@"
    url = NSURL.URLWithString address

    raise "Loading Error: #{err[0].description}" unless
      data = NSData.alloc.initWithContentsOfURL(
        url, options:0, error:err)

    raise "Parsing Error: #{err[0].description}" unless
      json = NSJSONSerialization.JSONObjectWithData(
        data, options:0, error:err)

    json
  end

  def refresh(endpoint)
    Dispatch::Queue.concurrent.async do
      begin
        response = get "http://reddit.com/#{endpoint}"
        data = response["data"]["children"].map {|i| RedditPost.new i["data"] }
        Dispatch::Queue.main.sync { @posts = data; view.reloadData }
      rescue Exception => msg
        puts "Loading Failed: #{msg}"
      end
    end
  end
end

class AppDelegate
  def application(app, didFinishLaunchingWithOptions:launchOptions)
    @win = UIWindow.alloc.initWithFrame(
            UIScreen.mainScreen.applicationFrame)

    @win.rootViewController = RedditController.alloc.initWithStyle(
                                  UITableViewStylePlain)

    @win.rootViewController.wantsFullScreenLayout = true
    @win.makeKeyAndVisible
    return true
  end
end

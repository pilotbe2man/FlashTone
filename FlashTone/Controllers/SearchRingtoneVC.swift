//
//  SearchRingtoneVC.swift
//  FlashTone
//
//  Created by Developer on 7/3/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit
import SwiftyJSON
import AVFoundation
import VeloxDownloader


class SearchRingtoneVC: UIViewController {

    @IBOutlet weak var tbl_songlist: UITableView!
    
    var array_songlist: NSMutableArray = []
    var string_search_name = ""
    
    var audio_play_index = -1
    var avPlayer: AVPlayer!
    var isPaused = false
    var isCellVisiable = false
    let downloader = VeloxDownloadManager.sharedInstance    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let nib = UINib(nibName:"AudiolistCell", bundle: nil)
        self.tbl_songlist.register(nib, forCellReuseIdentifier: "AudiolistCell")
        self.tbl_songlist.separatorColor = UIColor.init(red: 110/255, green: 124/255, blue: 178/255, alpha: 0.4)
        self.tbl_songlist.tableFooterView = UIView.init()
        self.songlistsLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backBtnClick(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func songlistsLoad()
    {
        Utills.showLoadingMessage(view: self.view, message: "")
        let typevalue = "SEARCH"
        let params = ["type"   :  typevalue,
                      "search_name": self.string_search_name] as [String : AnyObject]
        
        NetworkManager.sharedInstance.postRequest(url: URL_API_SERVER, paramameters: params) { (result, error) in
            Utills.hideLoadingMessage(view: self.view)
            if error != nil
            {
                Utills.showMessage(title: "Error", message: (error?.localizedDescription)!, parent: self)
            }
            else
            {
                if let response = result {
                    if let json = JSON(response).dictionaryObject {
                        let arr_json = json["response_data"] as! NSArray
                        self.array_songlist = arr_json.mutableCopy() as! NSMutableArray
                        self.tbl_songlist.reloadData()
                    }
                }
            }
        }
    }
    
    // play and pause audio file
    func audioplay(stringurl:String)
    {
        let url = URL(string: stringurl)
        if(VeloxCacheManagement.fileExistForURL(url: url!))
        {
            let cachesDirectoryURLPath = VeloxCacheManagement.cachesDirectoryURlPath()
            
            let audiofilepath = "\(cachesDirectoryURLPath.path)/\(url!.lastPathComponent)"
            
            self.playurl(url: URL(fileURLWithPath: audiofilepath), online: false)
            
        }
        else
        {
            self.playurl(url: URL(string:stringurl)!, online: true)
        }
    }
    
    func audiopause()
    {
        avPlayer.pause()
        self.isPaused = true
    }
    
    func playurl(url:URL, online: Bool) {
        
        if online == true && NetworkManager.sharedInstance.isInternetAvailable() == false
        {
            Utills.showMessage(title: "Error", message: "Please check network connection.", parent: self)
            return
        }
        
        self.avPlayer = AVPlayer(playerItem: AVPlayerItem(url: url))
        avPlayer!.volume = 1.0
        avPlayer.play()
    }
    
    @objc func tick(timer: Timer){
        if(avPlayer != nil)
        {
            let tbl_cell = timer.userInfo as! AudiolistCell
            if(isPaused == false){
                if(avPlayer.rate == 0){
                    avPlayer.play()
                }else{
                    
                }
            }
            if((avPlayer.currentItem?.asset.duration) != nil){
                let currentTime1 : CMTime = (avPlayer.currentItem?.asset.duration)!
                let seconds1 : Float64 = CMTimeGetSeconds(currentTime1)
                let max_time : Float = Float(seconds1)
                let currentTime : CMTime = (self.avPlayer?.currentTime())!
                let seconds : Float64 = CMTimeGetSeconds(currentTime)
                let current_time : Float = Float(seconds)
                
                tbl_cell.progressview.setProgress(current_time/max_time, animated: true)
            }
            else
            {
                print("Error")
            }
        }
    }
    
    @objc func didPlayToEnd() {
        
        if self.audio_play_index != -1
        {
            print("Audio --- Repeat")
            let indexPath = IndexPath(item: self.audio_play_index, section: 0)
            if let cell = self.tbl_songlist.cellForRow(at: indexPath) as? AudiolistCell
            {
                cell.progressview.setProgress(0.0, animated: false)
                
                self.avPlayer.seek(to: kCMTimeZero)
                self.avPlayer.play()
            }
            else
            {
                self.avPlayer = nil
                self.audio_play_index = -1
                self.tbl_songlist.reloadData()
            }
        }
    }

}
extension SearchRingtoneVC: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.array_songlist.count > 0
        {
            return self.array_songlist.count
        }
        else
        {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.array_songlist.count > 0
        {
            let cell  = tableView.dequeueReusableCell(withIdentifier: "AudiolistCell", for: indexPath) as! AudiolistCell
            cell.delegate = self
            
            if(self.audio_play_index != -1)
            {
                let previous_indexPath = IndexPath(item: self.audio_play_index, section: 0)
                if !((tableView.indexPathsForVisibleRows?.contains(previous_indexPath))!)
                {
                    cell.stopTimer()
                    self.avPlayer = nil
                    self.audio_play_index = -1
                }
            }            
            
            let song_dict = self.array_songlist[indexPath.row] as! NSDictionary
            cell.lbl_audio_name.text = song_dict["title"] as? String
            cell.lbl_audio_category.text = song_dict["category_name"] as? String
            
            let category_id = song_dict["category_id"] as? String
            let img_audio_play = Utills.getAudioplaybgIcon(Int(category_id!)!)
            cell.btn_play_pause.setBackgroundImage(img_audio_play, for: .normal)
            
            let duration = song_dict["duration"] as! String
            cell.lbl_audio_length.text = "\(duration) s"
            
            cell.btn_download.isHidden = true
            
            cell.backgroundColor = UIColor.clear
            cell.selectionStyle = .none
            
            if(self.audio_play_index != indexPath.row)
            {
                cell.stopTimer()
            }
            else
            {
                cell.btn_download.isHidden = false
            }
            
            return cell
        }
        else
        {
            let cell  = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            let label = cell.viewWithTag(101) as! UILabel
            label.text = "No content"
            return cell
        }
    }
}
extension SearchRingtoneVC: AudiolistCellDelegate
{
    func audioPlayPaused(_ cell: AudiolistCell)
    {
        if let indexPath = self.tbl_songlist.indexPath(for: cell)
        {
            let song_dict = self.array_songlist[indexPath.row] as! NSDictionary
            if let url = song_dict["p_song"] as? String
            {
                let url_audio = "\(URL_BASE_SERVER)\(url)"
                
                if (self.audio_play_index != -1 && self.audio_play_index != indexPath.row)
                {
                    
                    let previous_indexPath = IndexPath(item: self.audio_play_index, section: 0)
                    if let previous_tbl_cell = self.tbl_songlist.cellForRow(at: previous_indexPath) as? AudiolistCell
                    {
                        previous_tbl_cell.stopTimer()
                        self.isCellVisiable = true
                    }
                    else
                    {
                        self.isCellVisiable = false
                        self.tbl_songlist.reloadData()
                    }
                    
                }
                self.isCellVisiable = true
                
                if cell.flag_play_pause
                {
                    cell.btn_play_pause.setImage(#imageLiteral(resourceName: "icon_audio_play"), for: .normal)
                    self.audiopause()
                }
                else
                {
                    cell.btn_play_pause.setImage(#imageLiteral(resourceName: "icon_audio_pause"), for: .normal)
                    self.isPaused = false
                    if(self.audio_play_index != indexPath.row)
                    {
                        cell.progress_timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(CategoryDetailVC.tick), userInfo: cell, repeats: true)
                        self.audioplay(stringurl: url_audio)
                    }
                    else
                    {
                        self.avPlayer.play()
                    }
                }
                self.audio_play_index = indexPath.row
                cell.hideDownloadbtnfunc(false)
                cell.flag_play_pause = !cell.flag_play_pause
            }
            else
            {
                Utills.showMessage(title: "", message: "There is no any ringtone file.", parent: self)
                return
            }
        }
    }
    
    
    func audioDownloaded(_ cell: AudiolistCell)
    {
        
        if ((!UserDefaults.standard.bool(forKey: USER_MEMBERSIP_PREMIUM_STATUS)) || (Utills.userMembershipCheck() != RETURN_USER_MEMBERSIP_PREMIUM)) && CommentScreenController.starsClicked == false
        {
            let controller = self.storyboard?.instantiateViewController(withIdentifier: "PremiumVC")
            self.navigationController?.pushViewController(controller!, animated: false)
            return
        }
        
        
        if let indexPath = self.tbl_songlist.indexPath(for: cell)
        {
            let song_dict = self.array_songlist[indexPath.row] as! NSDictionary
            let download_audio_url_str = "\(URL_BASE_SERVER)\(String(describing: song_dict["p_song"] as! String))"
            let download_audio_url = URL(string: download_audio_url_str)
            if(VeloxCacheManagement.fileExistForURL(url: download_audio_url!))
            {
                Utills.showMessage(title: "", message: "You have already downloaded this file.", parent: self)
            }
            else
            {
                var save_flag = false
                Utills.showLoadingMessage(view: self.view, message: "")
                let progressClosure : (CGFloat,VeloxDownloadInstance) -> (Void)
                progressClosure = {(progress,downloadInstace) in
                }
                let remainingTimeClosure : (CGFloat) -> Void
                remainingTimeClosure = {(timeRemaning) in
                }
                let completionClosure : (Bool) -> Void
                completionClosure = {(status) in
                    DispatchQueue.main.async {
                        Utills.hideLoadingMessage(view: self.view)
                        if(!save_flag)
                        {
                            Utills.saveDownloadringtoneFunc(song_dict)
                            let songID = song_dict["id"] as! String
                            Utills.ringtoneUpdate(songID, view: self.view)
                            save_flag = true
                        }
                    }
                }
                
                downloader.downloadFile(withURL: download_audio_url!, name: download_audio_url!.lastPathComponent, directoryName: nil, friendlyName: nil, progressClosure: progressClosure, remainigtTimeClosure: remainingTimeClosure, completionClosure: completionClosure, backgroundingMode: false)
            }
            
        }
    }
}

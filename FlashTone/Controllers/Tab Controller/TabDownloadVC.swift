//
//  TabDownloadVC.swift
//  FlashTone
//
//  Created by Developer on 5/20/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit
import CoreData
import AVFoundation
import VeloxDownloader

class TabDownloadVC: UIViewController {

    var array_downloads_obj: [NSManagedObject] = []
    @IBOutlet weak var tbl_downloads: UITableView!
    
    var audio_play_index = -1
    var avPlayer: AVPlayer!
    var isPaused = false
    var isCellVisiable = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let nib = UINib(nibName:"AudiolistCell", bundle: nil)
        self.tbl_downloads.register(nib, forCellReuseIdentifier: "AudiolistCell")
        self.tbl_downloads.separatorColor = UIColor.init(red: 110/255, green: 124/255, blue: 178/255, alpha: 0.4)
        self.tbl_downloads.tableFooterView = UIView.init()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.getDownloadsData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(TabDownloadVC.didPlayToEnd), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillDisappear( _ animated: Bool) {
        super.viewWillDisappear(animated)
        self.avPlayer = nil
        
        if (self.audio_play_index != -1)
        {
            let previous_indexPath = IndexPath(item: self.audio_play_index, section: 0)
            let previous_tbl_cell = self.tbl_downloads.cellForRow(at: previous_indexPath) as! AudiolistCell
            previous_tbl_cell.stopTimer()
            self.audio_play_index = -1
        }
        
        self.array_downloads_obj.removeAll()
        self.tbl_downloads.reloadData()
    }
    
    @IBAction func btnflashClick(_ sender: Any) {
        let flashTutorialVC = storyboard?.instantiateViewController(withIdentifier: "TutorialFlashVC") as! TutorialFlashVC
        navigationController?.pushViewController(flashTutorialVC, animated: true)
    }
    
    func getDownloadsData()
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let managedObjectContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Downloads")
        do {
            self.array_downloads_obj = try managedObjectContext.fetch(fetchRequest)  as! [NSManagedObject]
            self.tbl_downloads.reloadData()            
        } catch {
            let fetchError = error as NSError
            print(fetchError)
        }
    }
    
    @IBAction func ringtoneButtonPressed(_ sender: Any) {
        let ringtoneTutorialVC = storyboard?.instantiateViewController(withIdentifier: "TutorialConnectVC") as! TutorialConnectVC
        navigationController?.pushViewController(ringtoneTutorialVC, animated: true)
    }
    
    
}
extension TabDownloadVC: UITableViewDelegate, UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.array_downloads_obj.count > 0
        {
            return self.array_downloads_obj.count
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
        
        if self.array_downloads_obj.count > 0
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
            
            
            let song_dict = self.array_downloads_obj[indexPath.row]
            cell.lbl_audio_name.text = song_dict.value(forKey: "title") as? String
            cell.lbl_audio_category.text = song_dict.value(forKey: "category") as? String
            
            if let duration = song_dict.value(forKey: "duration") as? String
            {
                cell.lbl_audio_length.text = "\(duration) s"
            }
            
            let category_id = song_dict.value(forKey: "category_id") as? String
            let img_audio_play = Utills.getAudioplaybgIcon(Int(category_id!)!)
            cell.btn_play_pause.setBackgroundImage(img_audio_play, for: .normal)
            
            
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
    
    
    // play and pause Audio file
    func audioplay(stringurl:String)
    {
        let url = URL(string: stringurl)
        if(VeloxCacheManagement.fileExistForURL(url: url!))
        {
            do{
                let cachesDirectoryURLPath = VeloxCacheManagement.cachesDirectoryURlPath()
                let audiofilepath = "\(cachesDirectoryURLPath.path)/\(url!.lastPathComponent)"
                
                self.playurl(url: URL(fileURLWithPath: audiofilepath), online: false)               
            }
            catch let error as NSError{
                print("error occured while trying to read cache dir \(error.localizedDescription)")
            }
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
            if let cell = self.tbl_downloads.cellForRow(at: indexPath) as? AudiolistCell
            {
                cell.progressview.setProgress(0.0, animated: false)
                
                self.avPlayer.seek(to: kCMTimeZero)
                self.avPlayer.play()
            }
            else
            {
                self.avPlayer = nil
                self.audio_play_index = -1
                self.tbl_downloads.reloadData()
            }
        }
    }
}

extension TabDownloadVC: AudiolistCellDelegate
{
    func audioPlayPaused(_ cell: AudiolistCell)
    {
        if let indexPath = self.tbl_downloads.indexPath(for: cell)
        {
            let song_dict = self.array_downloads_obj[indexPath.row]
            if let url = song_dict.value(forKey: "p_song") as? String
            {
                let url_audio = "\(URL_BASE_SERVER)\(url)"
                
                
                if (self.audio_play_index != -1 && self.audio_play_index != indexPath.row)
                {
                    let previous_indexPath = IndexPath(item: self.audio_play_index, section: 0)
                    if let previous_tbl_cell = self.tbl_downloads.cellForRow(at: previous_indexPath) as? AudiolistCell
                    {
                        previous_tbl_cell.stopTimer()
                        previous_tbl_cell.btn_download.isHidden = true
                        previous_tbl_cell.lbl_audio_length.isHidden = false
                        self.isCellVisiable = true
                    }
                    else
                    {
                        self.isCellVisiable = false
                        self.tbl_downloads.reloadData()
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
                        cell.progress_timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(TabDownloadVC.tick), userInfo: cell, repeats: true)
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
        }
        else
        {
            Utills.showMessage(title: "", message: "There is no any ringtone file.", parent: self)
            return
        }
        cell.btn_download.isHidden = true
        cell.lbl_audio_length.isHidden = false
    }
    
    func audioDownloaded(_ cell: AudiolistCell)
    {
        
    }
}

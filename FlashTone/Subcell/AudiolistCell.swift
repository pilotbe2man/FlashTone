//
//  AudiolistCell.swift
//  FlashTone
//
//  Created by Developer on 5/21/18.
//  Copyright © 2018 Developer. All rights reserved.
//

import UIKit

protocol AudiolistCellDelegate {
    func audioPlayPaused(_ cell: AudiolistCell)
    func audioDownloaded(_ cell: AudiolistCell)
}


class AudiolistCell: UITableViewCell {
    @IBOutlet weak var lbl_audio_name: UILabel!
    @IBOutlet weak var lbl_audio_category: UILabel!
    @IBOutlet weak var lbl_audio_length: UILabel!
    @IBOutlet weak var btn_download: UIButton!
    @IBOutlet weak var btn_play_pause: UIButton!
    @IBOutlet weak var progressview: UIProgressView!
    
    var delegate: AudiolistCellDelegate?
    var flag_play_pause = false
    var progress_timer: Timer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func btnPlayPauseClick(_ sender: Any) {
        self.delegate?.audioPlayPaused(self)
        
    }
    
    @IBAction func btnDownloadClick(_ sender: Any) {
        self.delegate?.audioDownloaded(self)
    }
    
    func hideDownloadbtnfunc(_ flag: Bool)
    {
        self.btn_download.isHidden = flag
        self.lbl_audio_length.isHidden = !flag
        self.progressview.isHidden = flag
    }
        
    func stopTimer()
    {
        if(self.progress_timer != nil)
        {
            self.progress_timer?.invalidate()
            self.progress_timer = nil
        }
        self.btn_play_pause.setImage(#imageLiteral(resourceName: "icon_audio_play"), for: .normal)
        self.progressview.setProgress(0.0, animated: false)
        self.flag_play_pause = false
        self.hideDownloadbtnfunc(true)
    }
    
}

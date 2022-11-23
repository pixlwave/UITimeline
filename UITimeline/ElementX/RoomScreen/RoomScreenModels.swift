//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import UIKit

enum RoomScreenViewModelAction {
    case displayVideo(videoURL: URL)
    case displayFile(fileURL: URL, title: String?)
}

enum RoomScreenViewAction {
    case loadPreviousPage
    case itemAppeared(id: String)
    case itemDisappeared(id: String)
    case itemTapped(id: String)
    case linkClicked(url: URL)
    case sendMessage
    case sendReaction(key: String, eventID: String)
    case cancelReply
    case cancelEdit
    case editAll
}

struct RoomScreenViewState {
    var roomId: String
    var roomTitle = ""
    var roomAvatar: UIImage?
    var items: [TextRoomTimelineItem] = []
    var isBackPaginating = false
    var showLoading = false
}

enum RoomScreenErrorType: Hashable {
    /// A specific error message shown in an alert.
    case alert(String)
}

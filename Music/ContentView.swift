import SwiftUI
import MediaPlayer

struct VolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        MPVolumeView(frame: .zero)
    }
    func updateUIView(_ view: MPVolumeView, context: Context) {
        //
    }
}

struct ContentView: View {

    @State var showSongView: Bool = false
    @State var showDocPicker: Bool = false
    @State var filePath: String = ""
    @State var query: String = ""
    @State var nowPlayingInfo: [String: Any] = [String: Any]()
    @State var image: UIImage? = nil
    @State var title: String? = nil
    @State var artist: String? = nil
    @State var duration: Double? = nil
    @StateObject var viewModel: ViewModel = ViewModel()
    @Environment(\.colorScheme) var colorScheme

    init() {
        //
    }

    var body: some View {
        if self.viewModel.music != [] {
            MainView()
        } else {
            FirstView()
        }
    }

    @ViewBuilder
    func FirstView() -> some View {
        Button {
            self.showDocPicker = true
        } label: {
            Text("Give access to downloads folder")
                .bold()
        }
        .sheet(isPresented: $showDocPicker) {
            DocumentPicker().environmentObject(self.viewModel)
        }
    }

    @ViewBuilder
    func MainView() -> some View {
        NavigationView {
            List(self.viewModel.getMusic(query: self.query), id:\.self) { url in
                Button {
                    UserDefaults.standard.set(url.lastPathComponent, forKey: "lastSong")
                    self.viewModel.lastSong = url.lastPathComponent
                    self.viewModel.nowPlaying = url
                    self.viewModel.player = AVPlayer(url: url)
                    self.setInfo()
                    self.viewModel.setupNowPlaying(url: url)
                    self.viewModel.play()
                } label: {
                    Text(url.lastPathComponent)
                        .lineLimit(1)
                }
            }
            .navigationTitle("Downloads")
            .searchable(text: $query)
            .onAppear {
                if self.viewModel.lastSong != "Not playing" {
                    let url = URL(fileURLWithPath: "\(self.viewModel.downloadsUrl!.path)/\(self.viewModel.lastSong)")
                    self.viewModel.nowPlaying = url
                    self.viewModel.player = AVPlayer(url: url)
                    self.viewModel.setupNowPlaying(url: url)
                    self.setInfo()
                }
            }
            .safeAreaInset(edge: .bottom) {
                BottomView()
            }
        }
    }

    @ViewBuilder
    func SongView() -> some View {
        VStack {
            Image(uiImage: self.image!)
                .frame(width: 500, height: 500, alignment: .center)
                .padding()
            VStack {
                Text(self.title!)
                    .bold()
                Text(self.artist!)
            }
            .frame(alignment: .leading)
            .padding()
            HStack(alignment: .center, spacing: 20) {
                Button {
                    if self.viewModel.nowPlaying != nil {
                        self.viewModel.prev()
                    }
                } label: {
                    Image(systemName: "backward.fill")
                        .imageScale(.large)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                Button {
                    if self.viewModel.isPlaying {
                        self.viewModel.pause()
                    } else {
                        self.viewModel.play()
                    }
                } label: {
                    Image(systemName: self.viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .imageScale(.large)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                Button {
                    if self.viewModel.nowPlaying != nil {
                        self.viewModel.next()
                    }
                } label: {
                    Image(systemName: "forward.fill")
                        .imageScale(.large)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
            }
            VolumeSlider()
               .frame(height: 40)
               .padding()
        }
        .onAppear { self.setInfo() }
        .onChange(of: self.viewModel.nowPlaying) { url in
            self.setInfo()
        }
    }

    func setInfo() {
        let playerItem = AVPlayerItem(url: self.viewModel.nowPlaying!)
        let metadataList = playerItem.asset.metadata
        for item in metadataList {
            switch item.commonKey {
                case .commonKeyTitle?:
                    self.title = item.stringValue ?? ""
                case .commonKeyArtist?:
                    self.artist = item.stringValue ?? ""
                case .commonKeyArtwork?:
                    if let data = item.dataValue,
                       let image = UIImage(data: data) {
                        self.image = image
                    }
                case .none: break
                default: break
            }
        }
//        self.viewModel.player.currentItem?.currentTime().seconds
        self.duration = self.viewModel.player.currentItem?.asset.duration.seconds
    }

    @ViewBuilder
    func BottomView() -> some View {
        HStack(alignment: .bottom, spacing: 15) {
            Button {
                self.showSongView.toggle()
            } label: {
                Text(self.viewModel.lastSong)
                    .lineLimit(1)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } .sheet(isPresented: $showSongView) {
                if self.image == nil || self.artist == nil || self.duration == nil || self.title == nil {
                    Text("Not playing")
                } else {
                    SongView()
                }
            }
            Spacer()
            Button {
                if self.viewModel.nowPlaying != nil {
                    self.viewModel.prev()
                }
            } label: {
                Image(systemName: "backward.fill")
                    .imageScale(.large)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            Button {
                if self.viewModel.isPlaying {
                    self.viewModel.pause()
                } else {
                    self.viewModel.play()
                }
            } label: {
                Image(systemName: self.viewModel.isPlaying ? "pause.fill" : "play.fill")
                    .imageScale(.large)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            Button {
                if self.viewModel.nowPlaying != nil {
                    self.viewModel.next()
                }
            } label: {
                Image(systemName: "forward.fill")
                    .imageScale(.large)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 15)
        .background(.ultraThinMaterial)
    }
}

class ViewModel: ObservableObject {
    @Published var music: [URL] = []
    @Published var isPlaying: Bool = false
    @Published var nowPlaying: URL? = nil
    @Published var downloadsUrl: URL? = nil
    @Published var lastSong: String = UserDefaults.standard.string(forKey: "lastSong") ?? "Not playing"
    @Published var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    @Published var player: AVPlayer = AVPlayer()

    init() {
        self.loadBookmark()
        try! self.audioSession.setCategory(.playback, mode: .default, options: [])
        try! self.audioSession.setActive(true)
        self.setupRemoteTransportControls()
    }

    func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [unowned self] event in
            if !self.isPlaying {
                self.play()
                return .success
            }
            return .commandFailed
        }
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [unowned self] event in
            if self.isPlaying {
                self.pause()
                return .success
            }
            return .commandFailed
        }
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            if self.nowPlaying != nil {
                self.next()
                return .success
            }
            return .commandFailed
        }
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [unowned self] event in
            if self.nowPlaying != nil {
                self.prev()
                return .success
            }
            return .commandFailed
        }
    }

    func setupNowPlaying(url: URL) {
        let playerItem = AVPlayerItem(url: url)
        let metadataList = playerItem.asset.metadata
        var nowPlayingInfo = [String: Any]()
        for item in metadataList {
            switch item.commonKey {
                case .commonKeyTitle?:
                    nowPlayingInfo[MPMediaItemPropertyTitle] = item.stringValue ?? ""
                case .commonKeyArtist?:
                    nowPlayingInfo[MPMediaItemPropertyArtist] = item.stringValue ?? ""
                case .commonKeyArtwork?:
                    if let data = item.dataValue,
                       let image = UIImage(data: data) {
                        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    }
                case .none: break
                default: break
            }
        }
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentItem?.currentTime().seconds
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.currentItem?.asset.duration.seconds
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    func play() {
        self.isPlaying = true
        self.player.play()
    }

    func pause() {
        self.isPlaying = false
        self.player.pause()
    }

    func next() {
        let index = self.music.firstIndex(of: self.nowPlaying!)!
        var url: URL
        if self.music[index] == self.music.last { url = self.music.first! }
        else { url = self.music[index + 1] }
        UserDefaults.standard.set(url.lastPathComponent, forKey: "lastSong")
        self.lastSong = url.lastPathComponent
        self.nowPlaying = url
        self.player = AVPlayer(url: url)
        self.setupNowPlaying(url: url)
        self.play()
    }

    func prev() {
        let index = self.music.firstIndex(of: self.nowPlaying!)!
        var url: URL
        if self.music[index] == self.music.first { url = self.music.last! }
        else { url = self.music[index - 1] }
        UserDefaults.standard.set(url.lastPathComponent, forKey: "lastSong")
        self.lastSong = url.lastPathComponent
        self.nowPlaying = url
        self.player = AVPlayer(url: url)
        self.setupNowPlaying(url: url)
        self.play()
    }

    func addBookmark(for url: URL) {
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }
        let bookmarkData = try! url.bookmarkData(options: .minimalBookmark, includingResourceValuesForKeys: nil)
        let uuid = UUID().uuidString
        let fileNames = try! FileManager.default.contentsOfDirectory(atPath: getAppSandboxDirectory().path)
        for fileName in fileNames {
            try! FileManager.default.removeItem(atPath: "\(getAppSandboxDirectory().path)/\(fileName)")
        }
        try! bookmarkData.write(to: getAppSandboxDirectory().appendingPathComponent(uuid))
        self.loadBookmark()
        self.downloadsUrl = url
    }

    func loadBookmark() {
        let files = try! FileManager.default.contentsOfDirectory(at: getAppSandboxDirectory(), includingPropertiesForKeys: nil)
        if files != [] {
            let bookmarkData = try! Data(contentsOf: files.first!)
            var isStale = false
            let url = try! URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
            self.downloadsUrl = url
            self.loadMusic()
        }
    }

    func loadMusic() {
        let directoryContents = try! FileManager.default.contentsOfDirectory(
            at: self.downloadsUrl!,
            includingPropertiesForKeys: nil
        )
        self.music = directoryContents.filter(\.isMP3)
    }

    func getMusic(query: String) -> [URL] {
        if query.isEmpty { return self.music }
        else { return self.music.filter { $0.lastPathComponent.lowercased().contains(query.lowercased()) } }
    }

    private func getAppSandboxDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    @EnvironmentObject private var viewModel: ViewModel

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = context.coordinator
        return documentPicker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        //
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            self.parent.viewModel.addBookmark(for: urls.first!)
        }
    }
}

extension URL {
    var typeIdentifier: String? { (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier }
    var isMP3: Bool { typeIdentifier == "public.mp3" }
    var localizedName: String? { (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName }
    var hasHiddenExtension: Bool {
        get { (try? resourceValues(forKeys: [.hasHiddenExtensionKey]))?.hasHiddenExtension == true }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.hasHiddenExtension = newValue
            try? setResourceValues(resourceValues)
        }
    }
}

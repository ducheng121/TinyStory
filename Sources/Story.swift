import Foundation
import Darwin

struct StoryOption: Codable { let title: String; let next: String }
struct StoryNode: Codable {
    let id: String
    let text: String
    let options: [StoryOption]
    var endingTitle: String? = nil
}
struct Story: Identifiable {
    let id: String
    let title: String
    let summary: String
    let nodes: [StoryNode]
    var start: String { "start" }
    var endingNodes: [StoryNode] { nodes.filter { $0.endingTitle != nil } }
    func node(_ id: String) -> StoryNode? { nodes.first { $0.id == id } }
}

// Branches diverge at each decision and converge only where the story explicitly reconnects.
// 每次选择产生分支，只在故事明确设置的衔接处汇合。
// Each row is: prose, option A, option B. Endings are title and prose.
// 每行依次为正文、选项A、选项B；结局数据依次为标题和正文。
enum StoryCatalog {
    static func make(_ id: String, _ title: String, _ summary: String, _ rows: [[String]], _ endings: [[String]]) -> Story {
        let ids = ["start", "s2a", "s2b", "s3a", "s3b", "s4a", "s4b"]
        let next = [["s2a","s2b"],["s3a","s3b"],["s3b","s3a"],["s4a","s4b"],["s4b","s4a"],["endA","endB"],["endB","endA"]]
        var nodes = rows.enumerated().map { i, row in
            StoryNode(id: ids[i], text: row[0], options: [StoryOption(title: row[1], next: next[i][0]), StoryOption(title: row[2], next: next[i][1])])
        }
        nodes += endings.enumerated().map { i, row in StoryNode(id: i == 0 ? "endA" : "endB", text: row[1], options: [], endingTitle: row[0]) }
        return Story(id: id, title: title, summary: summary, nodes: nodes)
    }
    static let legacy: [Story] = [
        make("last-letter", "末班来信", "一封盖着明天邮戳的信，留住了今晚的末班车。", [
            ["末班车离站前，你在空荡的候车室捡到一封信。信封上写着你的名字，邮戳却是明天。", "拆开信封", "寻找失主"],
            ["信里写着：别让旧站的灯熄灭。窗外，一个熟悉的背影正在离开，你也听见站长喊你的名字。", "追上背影", "询问站长"],
            ["列车员认出信封上的字迹，说写信的人每晚都来。站长保管着他的留言，那人此刻就在窗外。", "找站长", "追上背影"],
            ["你追到旧站门口，那人正把钥匙交给管理员。看见信封，他停下脚步：你终于愿意来了吗？", "请他留下", "问起那封信"],
            ["站长拿出一叠未寄出的信。最上面一封写着：如果今晚等不到你，我就搭末班车去远方。", "去追列车", "点亮旧灯"],
            ["旧灯亮起，朋友回过头来。列车还在等，他问你：今晚留下聊聊，还是把没说的话写给明天？", "留在今晚", "寄往明天"],
            ["朋友走向列车，临行前递来一张空白明信片：把想说的话写给明天吧。你也可以邀他回旧站坐坐。", "写下约定", "一起回去"]
        ], [["灯火重逢","你们在旧站读完了那些信。朋友笑着承认，明天的邮戳是他盖错的。幸好重逢没有再迟一天。"],["寄往明天","你按信上明天的日期写下见面约定。朋友登车前笑了：邮戳虽然盖错，明天的约定可不能再错过。"]]),
        make("rain-shop", "借雨小店", "这家店不卖伞，只借出一场你需要的雨。", [
            ["你躲进街角小店，柜台上摆着许多装雨的玻璃瓶。店主说，每人只能借一场雨，天亮前归还。", "借细雨", "借骤雨"],
            ["细雨落进掌心，发出旧钢琴的声音。店主说这来自一座废弃花园，那里曾经有个露天音乐会。", "去找花园", "问雨的主人"],
            ["瓶里的骤雨忽然安静下来。标签写着一个陌生人的名字，背面却画着你小时候常去的花园。", "问雨的主人", "去找花园"],
            ["花园里的琴已经生锈。守园人说，弹琴的女孩走后，花就不再开了，只有雨天还能听见旋律。", "让雨落下", "寻找女孩"],
            ["店主拿出一张旧照片：女孩如今住在对街，不再弹琴。她以为，早就没有人记得那场音乐会。", "敲她的门", "带雨回花园"],
            ["雨落在琴盖上，敲出熟悉的节拍。女孩循声来到花园，却停在门外，问你这里还有听众吗？", "为她鼓掌", "陪她听雨"],
            ["女孩坐在窗边，轻轻哼起旧曲。她说手指已经不够灵活，但你可以把这段旋律带回花园。", "记下旋律", "邀她同行"]
        ], [["雨中返场","女孩重新坐到琴前，街坊撑伞听完最后一曲。天亮前，你归还了空瓶。瓶底多了一阵掌声。"],["留住雨声","你将旋律记在花园门口，天亮前归还雨瓶。后来每逢下雨，总有人轻哼。女孩的歌没有被忘记。"]]),
        make("moon-post", "月亮邮差", "今晚最后一封信，收件地址是已经拆掉的家。", [
            ["你是今晚的月亮邮差。最后一封信没有门牌，只写着：送给还在等我回家的人。天就快亮了。", "沿旧街找", "询问信封"],
            ["旧街只剩一面矮墙，墙角的小猫追着你的影子。它脖子上的铜牌，刻着信封里隐约透出的名字。", "跟着小猫", "读出名字"],
            ["信封回答：我记得一碗热汤，却不记得路。远处的小猫突然抬头，像听见有人在叫它。", "读出名字", "跟着小猫"],
            ["小猫带你来到新楼，老人每天都在门口放一碗水。她说，搬家以后，怕远行的人找不到这里。", "递上信封", "问旧家的事"],
            ["念出名字后，矮墙映出从前的厨房。桌上留着一碗汤，你听见老人说：地址变了，家还在。", "记下新地址", "循着汤香走"],
            ["你循着汤香走进新家，老人认出了信上的字。她迟迟没有拆信，问你能否先陪她把汤热一热？", "陪她热汤", "先读来信"],
            ["信封上浮现出新的门牌。窗口的老人向你招手，你还来得及敲门，也可以把信轻放在窗台。", "放到窗台", "敲门进去"]
        ], [["一碗热汤","你陪老人喝完热汤，她才慢慢展开信。天亮前，你终于懂得，邮差送到的不只是纸上的消息。"],["新的门牌","晨光照亮信封上的新地址。老人读完信，把门牌擦得很亮。从此远行的人，再也不会找错家。"]]),
        make("sea-radio", "海边电台", "停播多年的电台，收到一条来自海上的点歌。", [
            ["你收拾停播的海边电台时，耳机里响起一个请求：能再放一遍那首歌吗？屏幕没有显示来电。", "回应声音", "查看日志"],
            ["对方说自己正在返航，却认不出岸上的灯。你找到旧海图，图角记着一组早已停用的频率。", "调到旧频率", "询问船名"],
            ["日志最后一页记着一艘失联的小船。旁边夹着点歌单，背面是一组旧频率和船长的签名。", "查询船名", "调到旧频率"],
            ["旧频率里传来年轻船长的求援录音，结尾是一首断掉的歌。你可以播出这段声音，也可以补完那首歌。", "播出录音", "补完那首歌"],
            ["退休的守塔人认出船名，说船长已经平安归来。只是当年为他点歌的人，没听到那句谢谢。", "请他来电台", "播放那首歌"],
            ["广播惊动了守塔人，他赶到电台，说自己就是当年的船长。麦克风亮起来，他问：还有人在听吗？", "打开话筒", "先放音乐"],
            ["守塔人来到电台，认出那首歌，承认自己就是船长。此时点歌人打来电话：让我听完，也可以聊聊。", "让歌播完", "把电话给他"]
        ], [["迟到的谢谢","船长对着话筒说出迟到多年的谢谢。电话那头笑了：我一直知道你会回来。港口的灯逐盏亮起。"],["为你重播","你让整首歌安静地播完。第二天，电台门口多了一盒旧磁带，上面写着：下次，也请为我点歌。"]]),
        make("cloud-tailor", "补云的人", "城市上空破了一个洞，修补材料只有两段回忆。", [
            ["清晨，城市上空的云破了一个洞。补云师递给你针线：要用一段回忆作补丁，你愿意挑哪一段？", "快乐的回忆", "遗憾的回忆"],
            ["你想起小时候放飞的风筝，线轴变成一团金线。补云师说，先找到风筝，或者问问等你的人。", "追寻风筝", "寻找旧友"],
            ["你想起一次没有说出口的道歉，掌心出现蓝线。旧友住在云洞另一边，一只风筝正朝那里飞。", "寻找旧友", "追寻风筝"],
            ["风筝挂在屋顶，尾巴上系着你和朋友写下的愿望。纸已经褪色，但约好一起旅行的字还很清楚。", "取下愿望", "叫朋友来看"],
            ["旧友拿出另一半线轴，说一直等你来取。你们都笑了，原来这些年，谁也没有真正忘记约定。", "约好出发", "一起补云"],
            ["你带着旧愿望与朋友会合，接好两段线。补云师问，要把愿望缝进天空，还是带着它重新出发？", "缝进天空", "带着出发"],
            ["朋友赶来帮你缝好云洞，随后背起行囊：要一起走完约好的旧路，还是先在云上留下见面的路标？", "走完旧路", "留下路标"]
        ], [["天空的路标","云上多了一只风筝的形状。你们约定每年在这里见面，抬头就能找到那段不再失约的时光。"],["重新出发","你把线轴装进行囊，和朋友走向车站。云洞被晨光轻轻补上，未完成的愿望终于有了下一页。"]])
    ]
    // Edition 2 keeps the first choice through to the final decision and outcome.
    // 第二版让第一次选择持续影响最后的决定和结局。
    static let all: [Story] = legacy.map { original in
        let branch: [[String]]
        let endings: [[String]]
        switch original.id {
        case "last-letter":
            branch = [["你没有拆信。朋友接过完好的信封，说里面是给旧站的告别信。他愿意留下，或请你替他投递。", "请他留下", "替他投递"],
                      ["朋友发现信封仍未拆开，便将旧站钥匙交给你：替我守住这间屋子，或者把告别信送出去吧。", "送出告别信", "接过钥匙"]]
            endings = [["旧站守信人", "你保留了信的秘密，也接过旧站的钥匙。朋友答应回来探望。从此灯亮起时，总有人在这里守候。"], ["替你告别", "你把未拆的信投入邮筒。朋友终于安心离开。这一次，你没有替他决定去留，只替他完成了告别。"]]
        case "rain-shop":
            branch = [["你借来的骤雨冲开了琴底暗格，露出女孩藏下的手稿。她赶来问你：让旧曲响起，还是写一首新的？", "演奏旧曲", "写首新曲"],
                      ["骤雨敲响窗沿，女孩翻出未完成的手稿。她想写进今天的雨声，也愿意为你再弹一遍旧日旋律。", "写进雨声", "重弹旧曲"]]
            endings = [["雨里的手稿", "骤雨替你找回了遗失的手稿。女孩照着旧谱弹完一曲，你归还雨瓶，把这段失而复得留在花园。"], ["新的雨季", "女孩把骤雨写进新曲，送你第一份乐谱。你准时还瓶，店主听见瓶里换了旋律，笑着收下它。"]]
        case "moon-post":
            branch = [["一路与你说话的信封终于承认，它也害怕被读完。老人愿意把它留下作伴，或让你带它继续送信。", "留下作伴", "带它同行"],
                      ["信封把新门牌告诉你，却舍不得告别。老人读完信，问你能否带它看更多的家，或留在窗边陪她。", "带它旅行", "留在窗边"]]
            endings = [["会说话的家书", "你从一开始就听见了信的心事。老人把它留在窗边，每晚和它说说话，远行的消息有了回声。"], ["邮差的伙伴", "老人留下信纸，将会说话的信封交给你。下个夜晚，它坐在你的邮袋里，替你记住每一盏归家的灯。"]]
        case "sea-radio":
            branch = [["你先翻出的日志证明，那句求援曾被漏记。船长看着空白的一栏，请你公开补录，或亲手交还给他。", "公开补录", "交还日志"],
                      ["歌声结束，船长问起你找到的日志。那页空白终于有了答案：你可以让他带走，也可以补入电台档案。", "让他带走", "补入档案"]]
            endings = [["补上的一页", "你在直播里补录了当年的求援与归航。船长亲口签下名字。这座电台终于留下完整的记录。"], ["带回岸上", "你将日志交给船长，让他自己决定如何讲述往事。他抱着本子走出电台，这次没再回头寻找信号。"]]
        default:
            branch = [["最初那段遗憾仍缠在线上。朋友听完你的道歉，愿意把结解开，也愿意把它留作不再失约的记号。", "解开线结", "留下记号"],
                      ["朋友指着蓝线上的结，说起那次没等到你的旅行。这一次，你可以留下结作提醒，或亲手把它解开。", "留下线结", "亲手解开"]]
            endings = [["解开的心结", "你说完迟到的道歉，朋友握着你的手解开蓝线。云缝平整了，你们终于不用带着那次遗憾出发。"], ["不再失约", "你们把线结留在云上，约好每次出发前都来看看。遗憾没有消失，却成了认真赴约的提醒。"]]
        }
        var nodes = [StoryNode(id: "start", text: original.node("start")!.text,
                               options: original.node("start")!.options.enumerated().map { i, o in StoryOption(title: o.title, next: (i == 0 ? "a-" : "b-") + o.next) })]
        for prefix in ["a-", "b-"] {
            for old in original.nodes where old.id != "start" && old.endingTitle == nil {
                // Only the first-choice-compatible second node is reachable.
                // 第二个节点只能沿第一次选择对应的分支到达。
                if old.id == (prefix == "a-" ? "s2b" : "s2a") { continue }
                let replacement = prefix == "b-" && old.id.hasPrefix("s4") ? branch[old.id == "s4a" ? 0 : 1] : nil
                let options = old.options.enumerated().map { i, option in
                    let next = option.next.hasPrefix("end") ? (prefix == "b-" ? (option.next == "endA" ? "endC" : "endD") : option.next) : prefix + option.next
                    return StoryOption(title: replacement?[i + 1] ?? option.title, next: next)
                }
                nodes.append(StoryNode(id: prefix + old.id, text: replacement?[0] ?? old.text, options: options))
            }
        }
        nodes += original.endingNodes
        nodes += endings.enumerated().map { i, row in StoryNode(id: i == 0 ? "endC" : "endD", text: row[1], options: [], endingTitle: row[0]) }
        return Story(id: original.id, title: original.title, summary: original.summary, nodes: nodes)
    } + [rainScore]
    // A hand-authored mystery: evidence routes and witness routes can corroborate
    // each other; a correct guess alone does not unlock the fully proven ending.
    // 手写探案分支：物证与证词可以相互印证，仅猜对答案不能解锁证据完整的结局。
    static let rainScore = Story(id: "rain-score", title: "雨夜失踪的曲谱",
        summary: "茶馆打烊前，手写曲谱不见了。窗边水迹与一只蓝铁盒，谁能解释？", nodes: [
        StoryNode(id: "start", text: "暴雨夜，茶馆的手写曲谱不见了。店主阿岚说送货员小周刚走，窗边还有水迹。你先查哪里？", options: [StoryOption(title: "查看窗台", next: "window"), StoryOption(title: "询问客人", next: "witness")]),
        StoryNode(id: "window", text: "外窗台湿透，内侧积灰却没有脚印。曲谱原处留着一根蓝布线，柜台上恰有一块蓝布。", options: [StoryOption(title: "核对蓝布", next: "cloth"), StoryOption(title: "追问小周", next: "courier")]),
        StoryNode(id: "witness", text: "客人说小周离开时提着纸箱，却没看见曲谱。他还记得停电前，阿岚抱着蓝铁盒走向柜台。", options: [StoryOption(title: "检查铁盒", next: "tin"), StoryOption(title: "核对纸箱", next: "parcel")]),
        StoryNode(id: "cloth", text: "布线与柜台蓝布的破口吻合。布下压着阿岚的便条：漏雨，曲谱移入蓝盒。柜台后有只蓝铁盒。", options: [StoryOption(title: "请她开盒", next: "proven"), StoryOption(title: "先指认小周", next: "accused")]),
        StoryNode(id: "courier", text: "小周说纸箱里是茶杯，愿意开箱。他记得阿岚说过屋顶漏雨，曾拿蓝布包起桌上一叠纸。", options: [StoryOption(title: "回店查蓝盒", next: "found"), StoryOption(title: "坚持查纸箱", next: "noProof")]),
        StoryNode(id: "tin", text: "铁盒旁有张阿岚署名的便条：漏雨，曲谱移入蓝盒。盒沿夹着蓝布，正是客人看见她抱走的那只。", options: [StoryOption(title: "请她开盒", next: "proven"), StoryOption(title: "先指认小周", next: "accused")]),
        StoryNode(id: "parcel", text: "小周当面打开纸箱，里面只有茶杯，送货单也对得上。他提醒你：阿岚收工前总会检查蓝铁盒。", options: [StoryOption(title: "回店查蓝盒", next: "found"), StoryOption(title: "继续找赃物", next: "noProof")]),
        StoryNode(id: "proven", text: "阿岚打开蓝盒，曲谱果然裹在蓝布里。她想起停电时忙着接漏水，忘了搬动曲谱。你如何结案？", options: [StoryOption(title: "串起证据", next: "endA"), StoryOption(title: "只报已找回", next: "endB")]),
        StoryNode(id: "found", text: "回店后，阿岚按你的请求打开蓝盒，找到了曲谱。但是谁放进去、为什么放，你还没有核实。", options: [StoryOption(title: "核实搬动原因", next: "endA"), StoryOption(title: "只报已找回", next: "endB")]),
        StoryNode(id: "accused", text: "你指认小周，他请你拿出证据。阿岚这时打开蓝盒，曲谱就在里面；她承认是自己避雨时收起的。", options: [StoryOption(title: "向小周道歉", next: "endC"), StoryOption(title: "仍保留怀疑", next: "endD")]),
        StoryNode(id: "noProof", text: "纸箱没有曲谱，也没人见小周拿走它。蓝铁盒还没查过。阿岚问你，能认定是谁拿走了吗？", options: [StoryOption(title: "暂不下结论", next: "endD"), StoryOption(title: "回店核实", next: "endA")]),
        StoryNode(id: "endA", text: "阿岚取出曲谱，出示移入蓝盒的便条：停电时为避漏雨收起，忙乱中忘了。便条与实物相合，小周洗清嫌疑。", options: [], endingTitle: "蓝盒里的真相"),
        StoryNode(id: "endB", text: "曲谱找回，演奏照常开始。你只报告物品平安，没有说明搬动经过。失物案结束了，小周却还等着一句澄清。", options: [], endingTitle: "找回之后"),
        StoryNode(id: "endC", text: "你撤回指认，向小周道歉。阿岚说明自己为避漏雨收起曲谱。小周接受了道歉：下次，先看证据再叫住我。", options: [], endingTitle: "迟来的澄清"),
        StoryNode(id: "endD", text: "你留下未结的调查记录。次日阿岚公布便条与蓝盒中的曲谱，证实只是避雨移放。没有证据，怀疑终究不是答案。", options: [], endingTitle: "未落笔的结论")
    ])

    static func story(_ id: String, version: Int = 2) -> Story? { (version == 1 ? legacy : all).first { $0.id == id } }

}

struct JourneyStep: Codable {
    let node: StoryNode
    let choice: String
    let optionTitle: String
}
struct Journey: Codable, Identifiable {
    let id: String
    let storyVersion: Int
    let steps: [JourneyStep]
    let lastNode: StoryNode
    let date: Date
    let reconstructed: Bool
    var completed: Bool { lastNode.endingTitle != nil }
}
struct StoryProgress: Codable {
    var contentVersion: Int? = 2
    var journeyID: String? = UUID().uuidString
    var steps: [JourneyStep]? = []
    var history: [Journey]? = []
    var reconstructed: Bool? = false
    var edition: Int { contentVersion ?? 1 }
    func snapshot(story: Story) -> Journey {
        Journey(id: journeyID ?? run, storyVersion: edition, steps: steps ?? [], lastNode: story.node(nodeID)!, date: updated, reconstructed: reconstructed ?? false)
    }

    var run = UUID().uuidString
    var nodeID = "start"
    var choices: [String] = []
    var endings: [String] = []
    var updated = Date()
}
struct ExploredBranch {
    let node: StoryNode
    let exits: [ExploredExit]
    var visibleIDs: Set<String> { exits.reduce(into: Set([node.id])) { result, exit in if let child = exit.child { result.formUnion(child.visibleIDs) } } }
}
struct ExploredExit {
    let label: String
    let child: ExploredBranch?
}
extension Story {
    func exploredTree(_ progress: StoryProgress) -> ExploredBranch {
        var edges = Set<String>()
        for journey in progress.history ?? [] where journey.storyVersion == progress.edition {
            for step in journey.steps { edges.insert(step.node.id + ":" + step.choice) }
        }
        for step in progress.steps ?? [] { edges.insert(step.node.id + ":" + step.choice) }
        func build(_ id: String, depth: Int) -> ExploredBranch {
            let node = self.node(id)!
            let exits = node.options.enumerated().map { index, option in
                let letter = index == 0 ? "A" : "B"
                return ExploredExit(label: "\(letter) · \(option.title)", child: depth < 4 && edges.contains(id + ":" + letter) ? build(option.next, depth: depth + 1) : nil)
            }
            return ExploredBranch(node: node, exits: exits)
        }
        return build(start, depth: 0)
    }
}
enum NextStoryOrder: String, Codable, CaseIterable {
    case unfinishedFirst, listOrder
    var title: String { self == .unfinishedFirst ? "优先未完成" : "按列表顺序" }
}
struct StoryState: Codable {
    var language: StoryLanguage? = nil
    var widgetPage: Int? = nil
    var languageToken: String { (language ?? .system).rawValue + ":" + (language ?? .system).resolved().rawValue }
    var readingPages: [String] { StoryPages.split(localizer(text), limit: (language ?? .system).resolved() == .english ? 100 : 60) }
    var pageIndex: Int { min(max(widgetPage ?? 0, 0), readingPages.count - 1) }
    var pageText: String { readingPages[pageIndex] }
    var lastPage: Bool { pageIndex == readingPages.count - 1 }
    var localizer: StoryLocalizer { StoryLocalizer(language: language ?? .system) }
    var nextStoryOrder: NextStoryOrder? = nil
    var version = 2
    var activeID = "last-letter"
    var progress: [String: StoryProgress] = [:]
    var story: Story { StoryCatalog.story(activeID, version: current.edition)! }
    var current: StoryProgress { progress[activeID] ?? StoryProgress() }
    var node: StoryNode { story.node(current.nodeID)! }
    var run: String { current.run }
    var step: Int { current.choices.count }
    var finished: Bool { node.endingTitle != nil }
    var ending: String { node.endingTitle ?? "" }
    var text: String { node.text }
    var options: [String] { node.options.map(\.title) }
    mutating func select(_ id: String) {
        if activeID != id { widgetPage = 0 }
        if progress[id] == nil { progress[id] = StoryProgress() }
        if activeID != id { progress[id]!.run = UUID().uuidString }
        activeID = id
    }
}
struct LegacyState: Codable { var run: String; var choices: [String]; var endings: [String]; var updated: Date }
enum StoreError: LocalizedError {
    case invalidData
    var errorDescription: String? { "暂时无法读取故事进度。原有数据已保留，请稍后重试。" }
}
struct StoryStore {
    static let group = "group.com.ducheng.story"
    static func directory() throws -> URL {
        #if os(macOS)
        if let path = ProcessInfo.processInfo.environment["MICROSTORY_TEST_DIRECTORY"] { return URL(fileURLWithPath: path) }
        #endif
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else { throw CocoaError(.fileNoSuchFile) }
        return url
    }
    static func prepareJourneys(_ state: inout StoryState) {
        for id in Array(state.progress.keys) {
            var p = state.progress[id]!
            guard let story = StoryCatalog.story(id, version: p.edition) else { continue }
            if p.steps == nil {
                var nodeID = story.start
                var steps: [JourneyStep] = []
                for choice in p.choices {
                    guard let node = story.node(nodeID), node.options.count == 2 else { break }
                    let option = node.options[choice == "A" ? 0 : 1]
                    steps.append(JourneyStep(node: node, choice: choice, optionTitle: option.title)); nodeID = option.next
                }
                p.steps = steps; p.reconstructed = true
            }
            if p.journeyID == nil { p.journeyID = UUID().uuidString }
            if p.history == nil { p.history = [] }
            if story.node(p.nodeID)?.endingTitle != nil { archive(&p, story: story) }
            state.progress[id] = p
        }
    }
    static func archive(_ p: inout StoryProgress, story: Story) {
        guard !p.choices.isEmpty else { return }
        let journey = p.snapshot(story: story)
        if !(p.history ?? []).contains(where: { $0.id == journey.id }) { p.history = (p.history ?? []) + [journey] }
    }
    static func freshProgress(_ old: StoryProgress?, id: String) -> StoryProgress {
        var old = old ?? StoryProgress()
        archive(&old, story: StoryCatalog.story(id, version: old.edition)!)
        var fresh = StoryProgress(); fresh.endings = old.endings; fresh.history = old.history
        return fresh
    }
    static func validate(_ state: StoryState) throws {
        guard state.version == 2, StoryCatalog.story(state.activeID) != nil, state.progress[state.activeID] != nil else { throw StoreError.invalidData }
        for (id, p) in state.progress {
            guard [1, 2].contains(p.edition), let story = StoryCatalog.story(id, version: p.edition), let node = story.node(p.nodeID), p.choices.count <= 4,
                  p.choices.allSatisfy({ ["A","B"].contains($0) }),
                  p.endings.allSatisfy({ StoryCatalog.story(id)!.node($0)?.endingTitle != nil }),
                  (node.endingTitle != nil) == (p.choices.count == 4) else { throw StoreError.invalidData }
        }
    }
    static func migrate(_ old: LegacyState) throws -> StoryState {
        guard old.choices.count <= 4, old.choices.allSatisfy({ ["A","B"].contains($0) }) else { throw StoreError.invalidData }
        var state = StoryState(); state.select("last-letter")
        var p = StoryProgress(); p.contentVersion = 1; p.steps = nil; p.choices = old.choices; p.updated = old.updated
        for c in old.choices { p.nodeID = StoryCatalog.story(state.activeID, version: 1)!.node(p.nodeID)!.options[c == "A" ? 0 : 1].next }
        // Completed validation saves retain the ending they actually saw.
        // 验证版中已完成的存档，保留用户当时实际读到的结局。
        if old.choices.count == 4 { p.nodeID = old.choices.filter { $0 == "A" }.count >= 2 ? "endA" : "endB" }
        p.endings = old.endings.compactMap { $0 == "灯火重逢" ? "endA" : ($0 == "寄往明天" ? "endB" : nil) }
        state.progress[state.activeID] = p
        return state
    }
    static func transaction(_ mutate: ((inout StoryState) -> Void)? = nil) throws -> StoryState {
        let dir = try directory()
        let fd = open(dir.appendingPathComponent("state.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard fd >= 0 else { throw CocoaError(.fileWriteUnknown) }
        defer { flock(fd, LOCK_UN); close(fd) }
        guard flock(fd, LOCK_EX) == 0 else { throw CocoaError(.fileWriteUnknown) }
        let url = dir.appendingPathComponent("library-v2.json")
        let exists = FileManager.default.fileExists(atPath: url.path)
        var state: StoryState
        if exists { state = try JSONDecoder().decode(StoryState.self, from: Data(contentsOf: url)) }
        else {
            let legacy = dir.appendingPathComponent("state.json")
            if FileManager.default.fileExists(atPath: legacy.path) { state = try migrate(JSONDecoder().decode(LegacyState.self, from: Data(contentsOf: legacy))) }
            else { state = StoryState(); state.select(state.activeID) }
        }
        try validate(state)
        prepareJourneys(&state)
        if let mutate { mutate(&state) }
        try validate(state)
        let encoded = try JSONEncoder().encode(state)
        try encoded.write(to: url, options: .atomic)
        return state
    }
    static func choose(_ choice: String, run: String, step: Int, page: Int? = nil, languageToken: String? = nil) throws {
        _ = try transaction { state in
            guard (page == nil || (page == state.pageIndex && state.lastPage)), (languageToken == nil || languageToken == state.languageToken), state.run == run, state.step == step, !state.finished, ["A","B"].contains(choice) else { return }
            var p = state.current
            let option = state.node.options[choice == "A" ? 0 : 1]
            p.steps = (p.steps ?? []) + [JourneyStep(node: state.node, choice: choice, optionTitle: option.title)]
            p.nodeID = state.node.options[choice == "A" ? 0 : 1].next
            p.choices.append(choice); p.updated = Date()
            if state.story.node(p.nodeID)!.endingTitle != nil && !p.endings.contains(p.nodeID) { p.endings.append(p.nodeID) }
            if state.story.node(p.nodeID)!.endingTitle != nil { archive(&p, story: state.story) }
            state.progress[state.activeID] = p
            state.widgetPage = 0
        }
    }
    // End-screen actions are checked inside the same lock as the mutation.
    // 结局页操作的校验和存档修改放在同一个锁内完成。
    static func finishAction(_ action: String, run: String, page: Int? = nil, languageToken: String? = nil) throws {
        _ = try transaction { state in
            guard (page == nil || (page == state.pageIndex && state.lastPage)), (languageToken == nil || languageToken == state.languageToken), state.run == run, state.finished else { return }
            state.widgetPage = 0
            if action == "restart" {
                state.progress[state.activeID] = freshProgress(state.current, id: state.activeID)
            } else if action == "next" {
                let index = StoryCatalog.all.firstIndex { $0.id == state.activeID }!
                let candidates = (1..<StoryCatalog.all.count).map { StoryCatalog.all[(index + $0) % StoryCatalog.all.count].id }
                let preferred = state.nextStoryOrder == .listOrder ? candidates.first : candidates.first(where: { (state.progress[$0]?.choices.count ?? 0) < 4 })
                guard let next = preferred ?? candidates.first else { return }
                if state.progress[next]?.choices.count == 4 {
                    state.progress[next] = freshProgress(state.progress[next], id: next)
                }
                state.select(next)
            }
        }
    }
    static func turnPage(_ delta: Int, run: String, step: Int, page: Int, languageToken: String) throws {
        _ = try transaction { state in
            guard [-1, 1].contains(delta), state.run == run, state.step == step,
                  state.pageIndex == page, state.languageToken == languageToken else { return }
            state.widgetPage = min(max(page + delta, 0), state.readingPages.count - 1)
        }
    }
    static func setLanguage(_ language: StoryLanguage) throws {
        _ = try transaction { state in
            if state.language != language { state.language = language; state.widgetPage = 0 }
        }
    }
    static func setNextStoryOrder(_ order: NextStoryOrder) throws {
        _ = try transaction { $0.nextStoryOrder = order }
    }
    static func select(_ id: String) throws {
        guard StoryCatalog.story(id) != nil else { throw StoreError.invalidData }
        _ = try transaction { $0.select(id) }
    }
    static func reset(_ id: String) throws {
        guard StoryCatalog.story(id) != nil else { throw StoreError.invalidData }
        _ = try transaction { state in
            state.progress[id] = freshProgress(state.progress[id], id: id); state.select(id); state.widgetPage = 0
        }
    }
}

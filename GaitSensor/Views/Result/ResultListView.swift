import SwiftUI

struct ResultListView: View {
    @Environment(\.managedObjectContext) var context
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.exam_id), SortDescriptor(\.end_unixtime)])
    var gaits: FetchedResults<Gait>
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.exam_id), SortDescriptor(\.unixtime)])
    var motionSensors: FetchedResults<MotionSensor>
    
    let gaitManager = GaitManager()
    
    let examTypeId: Int
    @State var isSelectedButton = false
    
    var body: some View {
        VStack {
            // 消費エネルギー
            VStack {
                if examTypeId == 0 {
                    Text("ウォーキングの記録").title()
                } else if examTypeId == 1 {
                    Text("歩行機能検査の記録").title()
                }
                Text("左スワイプでデータを削除できます").explain()
            }.padding(.top)
            
            if gaits.count >= 1 {
                List {
                    ForEach(lastGaitByExamId(gaits: gaits, examTypeId: examTypeId)) { gait in
                        HStack {
                            NavigationLink {
                                ResultView(gait: gait, showEnergy: (examTypeId == 0))
                            } label: {
                                Text(unixtimeToDateString(unixtimeMillis: Int(gait.start_unixtime), short: true))
                                Image(systemName: "shoeprints.fill").icon()
                                Text("\(gait.gait_steps) 歩")
                            }
                        }
                    }.onDelete(perform: delete)
                }
            } else {
                Color("Bg")
            }
        }.toolbar {
            ToolbarItem {
                Button {
                    isSelectedButton.toggle()
                } label: {
                    HStack{
                        Text("時系列で表示").toolbar()
                        Image(systemName: "chart.xyaxis.line").toolbarIcon()
                    }
                }
            }
        }.bgColor()
        
        NavigationLink(
            destination: ResultSequenceView(
                gaits: lastGaitByExamId(gaits: gaits, examTypeId: examTypeId),
                examTypeId: examTypeId),
            isActive: $isSelectedButton) { EmptyView() }
    }
    
    // Gaitは取得したタイミングで全部保存されているので、ExamIdごとに最後のみを使用する
    // また、同時にexamTypeIdも絞り込む
    func lastGaitByExamId(gaits: FetchedResults<Gait>, examTypeId: Int) -> [Gait] {
        let gaitDict = Dictionary(grouping: gaits, by: { $0.exam_id })
        var gaitList: [Gait] = []
        for elem in gaitDict {
            let gait = elem.value.last!
            if gait.exam_type_id == examTypeId {
                gaitList.append(gait)
            }
        }
        gaitList.sort(by: {$0.start_unixtime > $1.start_unixtime})
        return gaitList
    }

    // ExamIdに紐づくGaitとMotionSensorを削除する。
    func delete(offsets: IndexSet) {
        offsets.forEach { index in
            let lastGaits = lastGaitByExamId(gaits: gaits, examTypeId: examTypeId)
            let exam_id = Int(lastGaits[index].exam_id)
            gaitManager.deleteGait(gaits: gaits, examId: exam_id, context: context)
            gaitManager.deleteMotionSensor(motionSensors: motionSensors, examId: exam_id, context: context)
        }
    }
}


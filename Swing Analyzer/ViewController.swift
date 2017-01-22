//
//  ViewController.swift
//  Swing Analyzer
//
//  Created by Alexandra Kaulfuss on 16.11.16.
//  Copyright © 2016 Alexandra Kaulfuss. All rights reserved.
//

struct Swing {
    var loggingTime: [Date]
    var accelerationX: [Double]
    var accelerationY: [Double]
    var accelerationZ: [Double]
    var motionPitch: [Double]
    var motionRoll: [Double]
    var motionYaw: [Double]
    var rotationX: [Double]
    var rotationY: [Double]
    var rotationZ: [Double]
    
    init() {
        //loggingTime = [Date()]
        loggingTime = []
        accelerationX = []
        accelerationY = []
        accelerationZ = []
        rotationX = []
        rotationY = []
        rotationZ = []
        motionYaw = []
        motionRoll = []
        motionPitch = []
    }
}

import UIKit
import Charts
import CoreMotion
import CoreData
import SwiftyJSON
import AVFoundation

class ViewController: UIViewController, ChartViewDelegate, UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var sensorSegmentControl: UISegmentedControl!
    @IBOutlet weak var expertSegmentControl: UISegmentedControl!
    @IBOutlet weak var userDataTableView: UITableView!
    @IBOutlet weak var saveDataAsExpertButton: UIButton!
    @IBOutlet weak var timeSelectorSlider: UISlider!
    @IBOutlet weak var timeSelectorLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    
    let cmMotionManager = CMMotionManager()
    var operationQueue = OperationQueue()
    var timer: Timer!
    
    var selectedSensor = 0
    var selectedTime = 10
    var countdownSeconds = 10
    
    var expertData: Swing = Swing()
    var userData: Swing = Swing()
    var tempUserData: Swing = Swing()
    
    var newExpertData: Swing = Swing()
    var newUserData: Swing = Swing()
    
    var cdSwings: [CDSwing] = []
    var dataSets: [LineChartDataSet] = [LineChartDataSet]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timeSelectorSlider.setValue(Float(self.selectedTime), animated: false)
        timeSelectorLabel.text = String(self.selectedTime)
        countdownSeconds = selectedTime
        timeSelectorLabel.textAlignment = NSTextAlignment.right

        
        userDataTableView.dataSource = self
        userDataTableView.delegate = self
        
        self.cmMotionManager.deviceMotionUpdateInterval = 0.02
        
        self.lineChartView.delegate = self
        self.lineChartView.chartDescription?.text = ""
        self.lineChartView.noDataText = "keine Daten vorhanden"
        self.lineChartView.leftAxis.drawAxisLineEnabled = false
        self.lineChartView.leftAxis.drawGridLinesEnabled = false
        self.lineChartView.rightAxis.drawAxisLineEnabled = false
        self.lineChartView.rightAxis.drawGridLinesEnabled = false
        self.lineChartView.xAxis.drawAxisLineEnabled = true
        self.lineChartView.xAxis.drawGridLinesEnabled = false
        self.lineChartView.pinchZoomEnabled = false
        self.lineChartView.doubleTapToZoomEnabled = false
        self.lineChartView.isUserInteractionEnabled = false
        
        expertSegmentControl.selectedSegmentIndex = 0
        
        expertData = loadExpertData(expertFlag: 0)
        
        printChart(swing: expertData, sensor: selectedSensor, person: "expert")

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        //Daten aus CoreData laden
        getData()
        
        //TableView neu laden
        userDataTableView.reloadData()
    }
    
    
    func coreDataToStruct(cdSwing: CDSwing) -> Swing {
        var swing = Swing()
        
        var sensorDataCoreDataArray: [SensorData] = []
        let sensorDataFromCDSwing = cdSwing.sensorData
        for sensorData in sensorDataFromCDSwing! {
            sensorDataCoreDataArray.append(sensorData as! SensorData)
        }
        
        //SensorDaten werden als unsortiertes Set geladen, hier nach Zeit sortieren:
        sensorDataCoreDataArray.sort{($0.loggingTime as! Date) < ($1.loggingTime as! Date)}
        
        if !sensorDataCoreDataArray.isEmpty {

            for i in 0 ..< sensorDataCoreDataArray.count {
                swing.loggingTime.append(sensorDataCoreDataArray[i].loggingTime as! Date)
                swing.accelerationX.append(sensorDataCoreDataArray[i].accelerationX)
                swing.accelerationY.append(sensorDataCoreDataArray[i].accelerationY)
                swing.accelerationZ.append(sensorDataCoreDataArray[i].accelerationZ)
                swing.rotationX.append(sensorDataCoreDataArray[i].rotationX)
                swing.rotationY.append(sensorDataCoreDataArray[i].rotationY)
                swing.rotationZ.append(sensorDataCoreDataArray[i].rotationZ)
                swing.motionYaw.append(sensorDataCoreDataArray[i].motionYaw)
                swing.motionRoll.append(sensorDataCoreDataArray[i].motionRoll)
                swing.motionPitch.append(sensorDataCoreDataArray[i].motionPitch)
            }
        }
        return swing
    }
    
    /**
     * Lädt die Expertendaten aus einer JSON Datei.
     * expertFlag == 0 => die gespeicherten Standard Expertendaten
     * expertFlag == 1 => die neuen, vom Benutzer, gespeicherten Expertendaten
     */
    func loadExpertData(expertFlag: Int) -> Swing {
        
        var expertData = Swing()
        
        var path: String?
        
        if expertFlag == 0 {
            path = Bundle.main.path(forResource: "expertData", ofType: "json")
        }
        
        if expertFlag == 1 {
            let p = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            path = p.first
            if path != nil {
                path = path! + "/expertDataNew.json"
            }
        }
        
        if path != nil {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path!), options: .alwaysMapped)
                let jsonObj = JSON(data: data)
                
                if jsonObj != JSON.null {
                    
                    if let jsonArray =  jsonObj["loggingTime"].array {
                        for item in jsonArray {
                            if let temp = item.string {
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
                                let date = dateFormatter.date(from: temp)
                                expertData.loggingTime.append(date!)
                            }
                        }
                    }
                    expertData.accelerationX = jsonObj["accelerometerAccelerationX"].arrayValue.map({$0.double!})
                    expertData.accelerationY = jsonObj["accelerometerAccelerationY"].arrayValue.map({$0.double!})
                    expertData.accelerationZ = jsonObj["accelerometerAccelerationZ"].arrayValue.map({$0.double!})
                    expertData.rotationX = jsonObj["gyroRotationX"].arrayValue.map({$0.double!})
                    expertData.rotationY = jsonObj["gyroRotationY"].arrayValue.map({$0.double!})
                    expertData.rotationZ = jsonObj["gyroRotationZ"].arrayValue.map({$0.double!})
                    expertData.motionYaw = jsonObj["motionYaw"].arrayValue.map({$0.double!})
                    expertData.motionPitch = jsonObj["motionPitch"].arrayValue.map({$0.double!})
                    expertData.motionRoll = jsonObj["motionRoll"].arrayValue.map({$0.double!})
                } else {
                    print("Could not get json from file, make sure that file contains valid json.")
                }
            } catch {
                print("Datei nicht gefunden")
                print(error.localizedDescription)
            }
        } else {
            print("Could not find file for given filename/path")
        }
        return expertData
    }
    
    /**
        Die beiden Graphen aufeinander legen
    */
    func normalizeData() {
        newExpertData = Swing()
        newUserData = Swing()
        
        var startIexpert: Int = 0
        var arrayExpert = self.expertData.accelerationX
        if arrayExpert.count > 0 {
            for i in 0 ..< arrayExpert.count {
                if arrayExpert[i] > 0 {
                    startIexpert = i
                    break
                }
            }
        }
        
        let lengthNewExertData = arrayExpert.count - startIexpert
        
        var startIuser: Int = 0
        var arrayUser = self.userData.accelerationX
        if arrayUser.count > 0 {
            for i in 0 ..< arrayUser.count {
                if arrayUser[i] > 0 {
                    startIuser = i
                    break
                }
            }
        }
        
        let lengthNewUserData = arrayUser.count - startIuser
        
        let shortestArray = min(lengthNewUserData, lengthNewExertData)
        
        for i in 0 ..< shortestArray {
            newExpertData.loggingTime.append(expertData.loggingTime[startIexpert + i])
            newExpertData.accelerationX.append(expertData.accelerationX[startIexpert + i])
            newExpertData.accelerationY.append(expertData.accelerationY[startIexpert + i])
            newExpertData.accelerationZ.append(expertData.accelerationZ[startIexpert + i])
            newExpertData.rotationX.append(expertData.rotationX[startIexpert + i])
            newExpertData.rotationY.append(expertData.rotationY[startIexpert + i])
            newExpertData.rotationZ.append(expertData.rotationZ[startIexpert + i])
            newExpertData.motionYaw.append(expertData.motionYaw[startIexpert + i])
            newExpertData.motionRoll.append(expertData.motionRoll[startIexpert + i])
            newExpertData.motionPitch.append(expertData.motionPitch[startIexpert + i])
            
            newUserData.loggingTime.append(userData.loggingTime[startIuser + i])
            newUserData.accelerationX.append(userData.accelerationX[startIuser + i])
            newUserData.accelerationY.append(userData.accelerationY[startIuser + i])
            newUserData.accelerationZ.append(userData.accelerationZ[startIuser + i])
            newUserData.rotationX.append(userData.rotationX[startIuser + i])
            newUserData.rotationY.append(userData.rotationY[startIuser + i])
            newUserData.rotationZ.append(userData.rotationZ[startIuser + i])
            newUserData.motionYaw.append(userData.motionYaw[startIuser + i])
            newUserData.motionRoll.append(userData.motionRoll[startIuser + i])
            newUserData.motionPitch.append(userData.motionPitch[startIuser + i])
        }
    }
    
    /**
        Zeichnet einen Datensatz in das Chart
    */
    func printChart(swing: Swing, sensor: Int, person: String) {
        
        var valuesToPrint: [Double] = []
        
        switch sensor {
            case 0:
                valuesToPrint = swing.accelerationX
            case 1:
                valuesToPrint = swing.accelerationY
            case 2:
                valuesToPrint = swing.accelerationZ
            case 3:
                valuesToPrint = swing.rotationX
            case 4:
                valuesToPrint = swing.rotationY
            case 5:
                valuesToPrint = swing.rotationZ
            case 6:
                valuesToPrint = swing.motionYaw
            case 7:
                valuesToPrint = swing.motionRoll
            case 8:
                valuesToPrint = swing.motionPitch
            default:
                valuesToPrint = [0.0]
        }

        var chartValues:[ChartDataEntry] = [ChartDataEntry]()
        if valuesToPrint.count > 0 {
            for i in 0 ..< valuesToPrint.count {
                chartValues.append(ChartDataEntry(x: Double(i), y: valuesToPrint[i]))
            }
        } else {
            chartValues.append(ChartDataEntry(x: 0.0, y: 0.0))
        }

        
        var chartLabelText: String = ""
        var color: [UIColor] = [UIColor.white]
        
        switch person {
        case "expert":
            chartLabelText = "Experte"
            color = [UIColor.cyan]
        case "user":
            //Die Beschriftung für den Graph erstellen:
            if (swing.loggingTime.count > 0) {
            let timestamp = swing.loggingTime[0]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            var dateString = ""
            var timeString = ""
            dateString = dateFormatter.string(from: timestamp)
            timeString = timeFormatter.string(from: timestamp)
            chartLabelText = "\(dateString) - \(timeString)"
            color = [UIColor.red]
            }
        default:
            chartLabelText = ""
            color = [UIColor.cyan]
        }
        
        let set:LineChartDataSet = LineChartDataSet(values: chartValues, label: chartLabelText)
        set.axisDependency = .left
        set.mode = .cubicBezier
        set.drawCirclesEnabled = false
        set.colors = color
        dataSets.append(set)
        let data:LineChartData = LineChartData(dataSets: dataSets)
        self.lineChartView.data = data
    }
    
    /**
        erzeugt aus Swingdaten einen JSON String
    */
    func dataToJsonString() -> String {
        var s = "{ \"loggingTime\" : [\""
        
        for i in 0..<userData.loggingTime.count {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            let t = String(describing: dateFormatter.string(from: userData.loggingTime[i]))
            s = s.appending(t)
            s = s.appending("\",\"")
        }
        
        //letztes Anführungszeichen löschen
        s.remove(at: s.index(before: s.endIndex))
        //letzes Komma löschen
        s.remove(at: s.index(before: s.endIndex))
        
        s = s.appending("],\"accelerometerAccelerationX\" : [")
        
        for i in 0..<userData.accelerationX.count {
            let t = String(userData.accelerationX[i])
            s = s.appending(t)
            s = s.appending(",")
        }
        
        //letzes Komma löschen
        s.remove(at: s.index(before: s.endIndex))
        
        s = s.appending("],\"accelerometerAccelerationY\" : [")
        
        for i in 0..<userData.accelerationY.count {
            let t = String(userData.accelerationY[i])
            s = s.appending(t)
            s = s.appending(",")
        }
        
        //letzes Komma löschen
        s.remove(at: s.index(before: s.endIndex))
        
        s = s.appending("],\"accelerometerAccelerationZ\" : [")
        
        for i in 0..<userData.accelerationZ.count {
            let t = String(userData.accelerationZ[i])
            s = s.appending(t)
            s = s.appending(",")
        }
        
        //letzes Komma löschen
        s.remove(at: s.index(before: s.endIndex))
        
        s = s.appending("],\"gyroRotationX\" : [")
        
        for i in 0..<userData.rotationX.count {
            let t = String(userData.rotationX[i])
            s = s.appending(t)
            s = s.appending(",")
        }
        
        //letzes Komma löschen
        s.remove(at: s.index(before: s.endIndex))
        
        s = s.appending("],\"gyroRotationY\" : [")
        
        for i in 0..<userData.rotationY.count {
            let t = String(userData.rotationY[i])
            s = s.appending(t)
            s = s.appending(",")
        }
        
        //letzes Komma löschen
        s.remove(at: s.index(before: s.endIndex))
        
        s = s.appending("],\"gyroRotationZ\" : [")
        
        for i in 0..<userData.rotationZ.count {
            let t = String(userData.rotationZ[i])
            s = s.appending(t)
            s = s.appending(",")
        }
        
        //letzes Komma löschen
        s.remove(at: s.index(before: s.endIndex))
        
        s = s.appending("],\"motionYaw\" : [")
        
        for i in 0..<userData.motionYaw.count {
            let t = String(userData.motionYaw[i])
            s = s.appending(t)
            s = s.appending(",")
        }
        
        //letzes Komma löschen
        s.remove(at: s.index(before: s.endIndex))
        
        s = s.appending("],\"motionRoll\" : [")
        
        for i in 0..<userData.motionRoll.count {
            let t = String(userData.motionRoll[i])
            s = s.appending(t)
            s = s.appending(",")
        }
        
        //letzes Komma löschen
        s.remove(at: s.index(before: s.endIndex))
        
        s = s.appending("],\"motionPitch\" : [")
        
        for i in 0..<userData.motionPitch.count {
            let t = String(userData.motionPitch[i])
            s = s.appending(t)
            s = s.appending(",")
        }
        
        //letzes Komma löschen
        s.remove(at: s.index(before: s.endIndex))
        
        s = s.appending("]}")
        
        return s
    }
    
    //func saveDataToJsonFile(recordedDataSetStruct: RecordedDataSetStruct) {
    func saveDataToJsonFile() {
        let p = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        
        if let path = p.first {
            
            do {
                // Zeichenkette speichern
                let s = dataToJsonString()
                try s.write(toFile: path + "/expertDataNew.json", atomically : false , encoding: String.Encoding.utf8 )
                // Textdatei in eine Variable lesen
                //let t = try String(contentsOfFile: path + "/test.txt", encoding: String.Encoding.utf8 )
            } catch let err as NSError {
                print(err.description)
            }
        }
    }
    
    
    @IBAction func saveDataAsExpertAction(_ sender: Any) {
        saveDataToJsonFile()
    }
    
    
    /**
     * Die Sensordaten aufnehmen
     */
    @IBAction func startRecording(_ sender: Any) {
        AudioServicesPlaySystemSound(1003)
        self.countdownSeconds = self.selectedTime
        self.tempUserData = Swing()
        
        self.cmMotionManager.startDeviceMotionUpdates(to: operationQueue, withHandler: {
            
            (motionSensor, error) -> Void in
            if(error != nil) {
                NSLog("\(error)")
            } else {
                //Werte aufnehmen
                let logTime: Date = Date()
                self.tempUserData.loggingTime.append(logTime)
                
                let accel = motionSensor!.userAcceleration
                self.tempUserData.accelerationX.append(accel.x)
                self.tempUserData.accelerationY.append(accel.y)
                self.tempUserData.accelerationZ.append(accel.z)
                
                let rota = motionSensor!.rotationRate
                self.tempUserData.rotationX.append(rota.x)
                self.tempUserData.rotationY.append(rota.y)
                self.tempUserData.rotationZ.append(rota.z)
                
                let atti = motionSensor!.attitude
                self.tempUserData.motionYaw.append(atti.yaw)
                self.tempUserData.motionRoll.append(atti.roll)
                self.tempUserData.motionPitch.append(atti.pitch)
            }
        })
        
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(ViewController.update), userInfo: nil, repeats: true)
    }
    
    
    
    //läuft 12 Sekunden lang, dann werden die Daten aus Array in CoreData gespeichert
    func update() {
        if(self.countdownSeconds >= 0) {
            let s = String(self.countdownSeconds)
            timeSelectorLabel.text = s
            self.countdownSeconds -= 1
        } else {
            AudioServicesPlaySystemSound(1003) //1001
            
            timeSelectorLabel.text = String(selectedTime)
            cmMotionManager.stopDeviceMotionUpdates()
            timer.invalidate()
            saveDataToCoreData()
        }
    }
    
    
    /**
        Die aufgenommenen Daten in CoreData speichern
    */
    func saveDataToCoreData() {
        
        //Neuen Context (Verknüpfung zu CoreData) erstellen
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        
        //Neuen Datensatz erstellen
        let cdSwing = CDSwing(context: context)
        cdSwing.recordingTime = tempUserData.loggingTime[0] as NSDate?
        
        
        for i in 0..<tempUserData.loggingTime.count {
            
            //Die aufgenommenen Daten in ein SensorData Objekt speichern
            let sensorData = SensorData(context: context)
            
            sensorData.loggingTime = tempUserData.loggingTime[i] as NSDate?
            sensorData.accelerationX = tempUserData.accelerationX[i]
            sensorData.accelerationY = tempUserData.accelerationY[i]
            sensorData.accelerationZ = tempUserData.accelerationY[i]
            
            sensorData.rotationX = tempUserData.rotationX[i]
            sensorData.rotationY = tempUserData.rotationY[i]
            sensorData.rotationZ = tempUserData.rotationZ[i]
            
            sensorData.motionYaw = tempUserData.motionYaw[i]
            sensorData.motionRoll = tempUserData.motionRoll[i]
            sensorData.motionPitch = tempUserData.motionPitch[i]
            
            //Die gerade aufgenommenen Werte dem Datensatz hinzufügen
            cdSwing.addToSensorData(sensorData)
        }
        
        //Daten in CoreData speichern
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        
        //Daten aus CoreData laden
        getData()
        
        //TableView neu laden
        userDataTableView.reloadData()
        
    }    
    
    /**
     Lädt die Daten aus dem CoreData
    */
    func getData() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        do {
            cdSwings = try context.fetch(CDSwing.fetchRequest())
        } catch {
            print("Fetching failed")
        }
        
    }
    
    /**
     Gibt die Anzahl der aufgenommenen Datensätze = Anzahl der Tabellenzeilen zurück
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cdSwings.count
    }
    
    
    /**
     Schreibt die aufgenommenen Datensätze in die Tabellenzeilen
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let cdSwing = cdSwings[indexPath.row]
        let recordingTime = cdSwing.recordingTime
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        var dateString = ""
        var timeString = ""
        
        if recordingTime != nil {
            dateString = dateFormatter.string(from: recordingTime as! Date)
            timeString = timeFormatter.string(from: recordingTime as! Date)
            
            cell.textLabel?.text = "\(dateString) - \(timeString) Uhr"
        }
        return cell
    }
    
    
    /**
     Die Funktion löscht einen Datensatz aus der Tabelle, wenn geswiped wird
     */
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        
        if editingStyle == .delete {
            let cdSwing = cdSwings[indexPath.row]
            context.delete(cdSwing)
            (UIApplication.shared.delegate as! AppDelegate).saveContext()
            
            do {
                cdSwings = try context.fetch(CDSwing.fetchRequest())
            } catch {
                print("Fetching failed")
            }
        }
        tableView.reloadData()
    }
    
    
    /**
     Wenn eine Zeile in der Tabelle angeklickt wird:
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cdSwing = cdSwings[indexPath.row]
        userData = coreDataToStruct(cdSwing: cdSwing)
        dataSets.removeAll()
        normalizeData()
        printChart(swing: newExpertData, sensor: self.selectedSensor, person: "expert")
        printChart(swing: newUserData, sensor: self.selectedSensor, person: "user")
        
    }
    
    /**
     Wenn eine Zeile abgewählt wird:
     */
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
    }
    
    @IBAction func toggleSensorSegmentControl(_ sender: UISegmentedControl) {
        dataSets.removeAll()
        self.selectedSensor = sender.selectedSegmentIndex
        normalizeData()
        printChart(swing: newExpertData, sensor: self.selectedSensor, person: "expert")
        printChart(swing: newUserData, sensor: self.selectedSensor, person: "user")
    }

    
    @IBAction func toggleExpertSegmentControl(_ sender: UISegmentedControl) {
        dataSets.removeAll()
        expertData = loadExpertData(expertFlag: sender.selectedSegmentIndex)
        normalizeData()
        printChart(swing: newExpertData, sensor: self.selectedSensor, person: "expert")
        printChart(swing: newUserData, sensor: self.selectedSensor, person: "user")
    }
    
    @IBAction func slideTimeSelectorSlider(_ sender: UISlider) {
        self.selectedTime = Int(sender.value)
        timeSelectorLabel.text = String(self.selectedTime)
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An NSManagedObject subclass for the Media entity.
*/

import CoreData
import SwiftUI
import OSLog

// MARK: - Core Data

/// Managed object subclass for the Media entity.
class Media: NSManagedObject {

    @NSManaged var id:              String // UNIQUE
    @NSManaged var set:             String
    @NSManaged var idx:             Int64
    @NSManaged var cid:             Int64  // database change ID
    @NSManaged var hidden:          Bool
    @NSManaged var status:          String
    @NSManaged var type:            String
    @NSManaged var time:            Date
    @NSManaged var title:           String
    @NSManaged var device:          String
    @NSManaged var info1:           String
    @NSManaged var info2:           String
    @NSManaged var info3:           String
    @NSManaged var info4:           String
    @NSManaged var filename:        String // UNIQUE
    @NSManaged var code:            String
    @NSManaged var person:          String
    @NSManaged var company:         String
    @NSManaged var carrier:         String
    @NSManaged var location:        String
    @NSManaged var img:             String
    @NSManaged var imageData:       Data?


    /// Updates a Media instance with the values from a MediaProperties.
    func update(from mediaProperties: MediaProperties) throws {
        let dictionary = mediaProperties.dictionaryValue

        guard
            let new_id          = dictionary["id"]         as? String,
            let new_setName     = dictionary["setName"]    as? String,
            let new_idx         = dictionary["idx"]        as? Int64,
            let new_cid         = dictionary["cid"]        as? Int64,
            let new_hidden      = dictionary["hidden"]     as? Bool,
            let new_status      = dictionary["status"]     as? String,
            let new_type        = dictionary["type"]       as? String,
            let new_time        = dictionary["status"]     as? Date,
            let new_title       = dictionary["title"]      as? String,
            let new_device      = dictionary["device"]     as? String,
            let new_info1       = dictionary["info1"]      as? String,
            let new_info2       = dictionary["info2"]      as? String,
            let new_info3       = dictionary["info3"]      as? String,
            let new_info4       = dictionary["info4"]      as? String,
            let new_filename    = dictionary["filename"]   as? String,
            let new_code        = dictionary["code"]       as? String,
            let new_person      = dictionary["person"]     as? String,
            let new_company     = dictionary["company"]    as? String,
            let new_carrier     = dictionary["carrier"]    as? String,
            let new_location    = dictionary["location"]   as? String,
            let new_img         = dictionary["img"]        as? String,
            let new_imageData   = dictionary["imgageData"] as? Data

        else {
            throw DscanError.missingData
        }


        id             = new_id
        set            = new_setName
        idx            = new_idx
        cid            = new_cid
        hidden         = new_hidden
        status         = new_status
        type           = new_type
        time           = new_time
        title          = new_title
        device         = new_device
        info1          = new_info1
        info2          = new_info2
        info3          = new_info3
        info4          = new_info4
        filename       = new_filename
        code           = new_code
        person         = new_person
        carrier        = new_carrier
        company        = new_company
        location       = new_location
        img            = new_img
        imageData      = new_imageData

        print ("#\(id) \(set).\(idx): '\(code)' carrier:\(carrier) person:\(person) data:\(String(describing: imageData?.count))")
    }
}

// MARK: - SwiftUI

extension Media {

    override var description: String {
        return  "id:\(id.description       ), "
        +      "set:\(set.description      ), "
        +      "idx:\(idx.description      ), "
        +      "cid:\(cid.description      ), "
        +   "hidden:\(hidden.description   ), "
        +   "status:\(status.description   ), "
        +     "type:\(type.description     ), "
        +     "time:\(time.description     ), "
        +    "title:\(title.description    ), "
        +   "device:\(device.description   ), "
        +    "info1:\(info1.description    ), "
        +    "info2:\(info2.description    ), "
        +    "info3:\(info3.description    ), "
        +    "info4:\(info4.description    ), "
        + "filename:\(filename.description ), "
        +     "code:\(code.description     ), "
        +   "person:\(person.description   ), "
        +  "company:\(company.description  ), "
        +  "carrier:\(carrier.description  ), "
        + "location:\(location.description ), "
        +      "img:\(img.description      )"
    }

    /// An earthmedia for use with canvas previews.
    static var preview: Media {
        let media = Media.makePreviews(count: 1)
        return media[0]
    }

    @discardableResult
    static func makePreviews(count: Int64) -> [Media] {
        var media = [Media]()
        let viewContext = MediaProvider.preview.container.viewContext
        for index in 0..<count {
            let med = Media(context: viewContext)
            med.id = index.formatted()
            med.idx = index
            med.cid = 2334243
            med.hidden = false
            med.status = "scanned"
            med.type = "scan"
            med.time = Date().addingTimeInterval(Double(index) * -300)
            med.title = "\(med.time)"
            med.set = "\(med.time)"
            med.carrier = "DHL"
            med.code = "003783687638762"
            med.img = "http://localhost/ords/dscan/media/files/20210312_10:04:19.2890_5.jpg"
            media.append(med)
        }
        return media
    }
}

// MARK: - Codable

/// A struct for decoding JSON with the following structure:
///
/// {
///  "items":
///      [
///          {       "id": 582,
///              "content_type": "image/jpg",
///              "file_name": "20210312_09:45:14.3650_1.jpg",
///              "type": "scan",
///              "title": "20210312-09:45:14-0000",
///              "timestamp": "2021-03-12T09:45:14.365Z",
///              "idx": 0,
///              "content_size": 137520,
///              "device": "iPhone",
///              "carrier": " - unbekannt -",
///              "trackingnr": "456898901",
///              "name": " - unbekannt -",
///              "fulltext": "WERK WOLFSBURG⸱VOLKSWAGEN AG⸱10155\n(3) Lieferschein-Nr. (N)⸱38436 WOLFSBURG\n4568989⸱BOSCH ES-ST/CLP⸱(4) Lieferantenanschrift (Kurzname, Werk, PLZ, Ort)⸱MADE IN GERMANY⸱31132 HILDESHEIM\n577⸱(5) Gewicht netto⸱KG⸱727⸱(6) Gewicht brutto⸱KG⸱2⸱(7) Anzahl Packstücke\n02Z911023F⸱(8) Sach-Nr, Kunde (P)\n(9) Füllmenge (Q)⸱160⸱STARTER⸱(10) Bezeichnung Lieferung, Leistung\n0001123013/125/90⸱(11) Sach-Nr. Lieferant (30S)\n112) Lieferanten-Nr. (V)⸱01283/2⸱3.2.⸱0006PAL\nD030521⸱(13) Datum⸱| (14) Anderungsstand Konstruktion\n(15) Packstück-Nr. (S)⸱456898901⸱(16) Chargen-Nr. (H)\n(17) ROBERT BOSCH GmbH⸱POSTFACH 410 31132 HILDESHEIM⸱3 A⸱Warenanhänger VDA 4902, Version 4⸱BVE 15090-4⸱07:07⸱21.05.0\n",
///              "codelist": "Code39 ➜ <b>Q160</b><br>Code39 ➜ <b>V01283/2</b><br>Code39 ➜ <b>P02Z911023F</b><br>Code39 ➜ <b>N4568989</b>",
///              "taglist": "🏷 TrackingNr ➜ <b>456898901</b>\n🏷 Company ➜ <b> ROBERT BOSCH GmbH</b>",
///              "html_details": "<strong style=\"font-size:125%;\">20210312-09:45:14-0000</strong><br><br>🗓 12.03.2021 09:45:14 - 0<br>📷 iPhone<br>📃 <a href=\"http://localhost/ords/dscan/media/files/20210312_09:45:14.3650_1.jpg\">20210312_09:45:14.3650_1.jpg</a><br>📎 <a href=\"http://localhost/ords/dscan/media/files/20210312_09:45:14.3650_1.json\">20210312_09:45:14.3650_1.json</a><br><hr>Code39 ➜ <b>Q160</b><br>Code39 ➜ <b>V01283/2</b><br>Code39 ➜ <b>P02Z911023F</b><br>Code39 ➜ <b>N4568989</b>",
///              "month": "2021-03",
///              "day": "2021-03-12",
///              "set_name": "20210312-09:45:14",
///              "img": "http://localhost/ords/dscan/media/files/20210312_09:45:14.3650_1.jpg"
///          }
///      ]
///  }
///
/// Stores an array of decoded QuakeProperties for later use in
/// creating or updating Quake instances.
struct MediaJSON: Decodable {

    private enum RootCodingKeys: String, CodingKey {
        case items
    }


    private(set) var mediaPropertiesList = [MediaProperties]()

    private struct AlwaysDecodable: Decodable {}

    init(from decoder: Decoder) throws {
        let rootContainer  = try decoder.container(keyedBy: RootCodingKeys.self)
        var itemsContainer = try rootContainer.nestedUnkeyedContainer(forKey: .items)

        while !itemsContainer.isAtEnd {
            // from https://medium.com/mobimeo-technology/safely-decoding-enums-in-swift-1df532af9f42
            //let mediaContainer = try itemsContainer.nestedContainer(keyedBy: MediaProperties.CodingKeys.self)

            do {
                try mediaPropertiesList.append(itemsContainer.decode(MediaProperties.self))
                    //result.append(container.decode(T.self))
            }
            catch {
                let _ = try itemsContainer.decode(AlwaysDecodable.self)
            }


//            // Decodes a single media entry from the data, and appends it to the array, ignoring invalid data.
//            if let properties = try? itemsContainer.decode(MediaProperties.self) {
//                mediaPropertiesList.append(properties)
//            }
            //else itemsContainer.decode(MediaProperties.self)
        }
    }
}


/// A struct encapsulating the properties of a Media.
struct MediaProperties: Decodable {

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case id
        case set         = "set_name"
        case idx
        case cid
        case hidden
        case status
        case type
        case time        = "timestamp"
        case title
        case device
        case info1
        case info2
        case info3
        case info4
        case filename    = "file_name"
        case code        = "trackingnr"
        case person
        case company
        case location
        case carrier
        case img
        case recognizedCodesJson
        case recognizedTextJson
        case imageData
    }

    let id:                     String
    let set:                    String
    let idx:                    Int
    let cid:                    Int
    let hidden:                 Bool
    let status:                 String
    let type:                   String
    let time:                   Date
    let title:                  String
    let device:                 String
    let info1:                  String
    let info2:                  String
    let info3:                  String
    let info4:                  String
    let filename:               String
    let code:                   String
    let person:                 String
    let company:                String
    let carrier:                String
    let location:               String
    let img:                    String
    let recognizedCodesJson:    String
    let recognizedTextJson:     String
    let imageData:              Data
//    let uiImage:                UIImage?

    init (
        id:                     String,
        set:                    String,
        idx:                    Int,
        cid:                    Int,
        hidden:                 Bool,
        status:                 String,
        type:                   String,
        time:                   Date,
        title:                  String,
        device:                 String,
        info1:                  String,
        info2:                  String,
        info3:                  String,
        info4:                  String,
        filename:               String,
        code:                   String,
        person:                 String,
        company:                String,
        carrier:                String,
        location:               String,
        img:                    String,
        recognizedCodesJson:    String,
        recognizedTextJson:     String,
        imageData:              Data
//        uiImage:                UIImage
    ) {
        self.id                     = id
        self.set                    = set
        self.idx                    = idx
        self.cid                    = cid
        self.hidden                 = hidden
        self.status                 = status
        self.type                   = type
        self.time                   = time
        self.title                  = title
        self.device                 = device
        self.info1                  = info1
        self.info2                  = info2
        self.info3                  = info3
        self.info4                  = info4
        self.filename               = filename
        self.code                   = code
        self.person                 = person
        self.company                = company
        self.carrier                = carrier
        self.location               = location
        self.img                    = img
        self.recognizedCodesJson    = recognizedCodesJson
        self.recognizedTextJson     = recognizedTextJson
        self.imageData              = imageData
//        self.uiImage                = uiImage
    }



    init(from decoder: Decoder) throws {

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmssSSS"

        let values = try decoder.container(keyedBy: CodingKeys.self)

        let raw_id         = try? values.decode (Int.self,      forKey: .id         )
        let raw_set        = try? values.decode (String.self,   forKey: .set        )
        let raw_idx        = try? values.decode (Int.self,      forKey: .idx        )
        let raw_cid        = try? values.decode (Int.self,      forKey: .cid        )
        let raw_hidden     = try? values.decode (Bool.self,     forKey: .hidden     )
        let raw_status     = try? values.decode (String.self,   forKey: .status     )
        let raw_type       = try? values.decode (String.self,   forKey: .type       )
        let raw_title      = try? values.decode (String.self,   forKey: .title      )
        let raw_device     = try? values.decode (String.self,   forKey: .device     )
        let raw_info1      = try? values.decode (String.self,   forKey: .info1      )
        let raw_info2      = try? values.decode (String.self,   forKey: .info2      )
        let raw_info3      = try? values.decode (String.self,   forKey: .info3      )
        let raw_info4      = try? values.decode (String.self,   forKey: .info4      )
        let raw_filename   = try? values.decode (String.self,   forKey: .filename   )
        let raw_code       = try? values.decode (String.self,   forKey: .code       )
        let raw_person     = try? values.decode (String.self,   forKey: .person     )
        let raw_company    = try? values.decode (String.self,   forKey: .company    )
        let raw_carrier    = try? values.decode (String.self,   forKey: .carrier    )
        let raw_location   = try? values.decode (String.self,   forKey: .location   )
        let raw_img        = try? values.decode (String.self,   forKey: .img        )
        let raw_RCJ        = try? values.decode (String.self,   forKey: .recognizedCodesJson  )
        let raw_RTJ        = try? values.decode (String.self,   forKey: .recognizedTextJson   )
        let raw_ID         = try? values.decode (Data.self,     forKey: .imageData            )

        let raw_time       = try? formatter.date(from: values.decode (String.self,   forKey: .time ))

        let hidden              = raw_hidden ?? false
        let status              = raw_status ?? ""
        let code                = raw_code
        let person              = raw_person
        let company             = raw_company
        let carrier             = raw_carrier
        let location            = raw_location
        let img                 = raw_img
        let info1               = raw_info1
        let info2               = raw_info2
        let info3               = raw_info3
        let info4               = raw_info4
        let recoginzedCodesJson = raw_RCJ
        let recoginzedTextJson  = raw_RTJ
        let imageData           = raw_ID

        // Ignore instances with missing data.
        guard
            let id              = raw_id,
            let set             = raw_set,
            let idx             = raw_idx,
            let cid             = raw_cid,
            let type            = raw_type,
            let time            = raw_time,
            let title           = raw_title,
            let device          = raw_device,
            let filename        = raw_filename

        else {
            let values =    "id:\(String(describing: raw_id       )), "
              +            "set:\(String(describing: raw_set      )), "
              +            "idx:\(String(describing: raw_idx      )), "
              +            "cid:\(String(describing: raw_cid      )), "
              +         "hidden:\(String(describing: raw_hidden   )), "
              +         "status:\(String(describing: raw_status   )), "
              +           "type:\(String(describing: raw_type     )), "
              +           "code:\(String(describing: raw_code     )), "
              +           "time:\(String(describing: raw_time     )), "
              +          "title:\(String(describing: raw_title    )), "
              +         "device:\(String(describing: raw_device   )), "
              +       "filename:\(String(describing: raw_filename )), "
              +        "carrier:\(String(describing: raw_carrier  )), "
              +         "person:\(String(describing: raw_person   )), "
              +            "img:\(String(describing: raw_img      ))"

            let logger = Logger(subsystem: "de.hal9ccc.dscan", category: "parsing")
            logger.debug("Ignored: \(values)")

            throw DscanError.missingData
        }

        self.id                     = id.formatted()
        self.set                    = set
        self.idx                    = idx
        self.cid                    = cid
        self.hidden                 = hidden
        self.status                 = status
        self.type                   = type
        self.time                   = time
        self.title                  = title
        self.device                 = device
        self.info1                  = info1    ?? ""
        self.info2                  = info2    ?? ""
        self.info3                  = info3    ?? ""
        self.info4                  = info4    ?? ""
        self.filename               = filename
        self.code                   = code     ?? "␀"
        self.person                 = person   ?? "␀"
        self.company                = company  ?? "␀"
        self.carrier                = carrier  ?? "␀"
        self.location               = location ?? "␀"
        self.img                    = img      ?? "␀"
        self.recognizedCodesJson    = recoginzedCodesJson ?? "␀"
        self.recognizedTextJson     = recoginzedTextJson  ?? "␀"
        self.imageData              = imageData ?? Data()
        //self.uiImage                = nil
    }

    // The keys must have the same name as the attributes of the Media entity.
    var dictionaryValue: [String: Any] {
       ["id":                   id,
        "set":                  set,
        "idx":                  idx,
        "cid":                  cid,
        "hidden":               hidden,
        "status":               status,
        "type":                 type,
        "time":                 time,
        "title":                title,
        "device":               device,
        "info1":                info1,
        "info2":                info2,
        "info3":                info3,
        "info4":                info4,
        "filename":             filename,
        "code":                 code,
        "person":               person,
        "company":              company,
        "carrier":              carrier,
        "location":             location,
        "img":                  img,
        "recognizedCodesJson":  recognizedCodesJson,
        "recognizedTextJson":   recognizedTextJson,
        "imageData":            imageData
       ]
    }



}

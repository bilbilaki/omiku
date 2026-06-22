package main

/*
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
// Mocking Dart Native API types so Go can compile without the actual header file
typedef int64_t Dart_Port;

typedef enum {
    Dart_CObject_kNull = 0,
    Dart_CObject_kBool,
    Dart_CObject_kInt32,
    Dart_CObject_kInt64,
    Dart_CObject_kDouble,
    Dart_CObject_kString,
    Dart_CObject_kArray,
    Dart_CObject_kTypedData,
    Dart_CObject_kExternalTypedData,
    Dart_CObject_kUnsupported,
    Dart_CObject_kNumberOfTypes
} Dart_CObject_Type;

typedef struct _Dart_CObject {
    Dart_CObject_Type type;
    union {
        bool as_bool;
        int32_t as_int32;
        int64_t as_int64;
        double as_double;
        char* as_string;
    } value;
} Dart_CObject;

// This function pointer will hold the pointer to Dart_PostCObject
typedef bool (*Dart_PostCObject_Type)(Dart_Port port_id, Dart_CObject* message);

static bool CallDartPostCObject(Dart_PostCObject_Type fp, Dart_Port port_id, Dart_CObject* message) {
    return fp(port_id, message);
}
*/
import "C"
import (
	"encoding/json"
	"fmt"
	"unsafe"
)

var dartPostCObject C.Dart_PostCObject_Type

//export InitializeDartAPI
func InitializeDartAPI(apiPointer C.Dart_PostCObject_Type) {
	dartPostCObject = apiPointer
}

var guestClient *MALGuestClient

//export InitGuestClient
func InitGuestClient() {
	// The client instantiates cleanly because BuildTimeClientID is already populated in memory!
	guestClient = NewMALGuestClient()
}

//export NativeSearchMangaAniList
func NativeSearchMangaAniList(port C.Dart_Port, queryi *C.char) {
	query := C.GoString(queryi)
	if guestClient == nil {
		InitGuestClient()
	}
	go func(q string) {
		jsonResp, err := guestClient.SearchMangaAniList(q)
		if err != nil {
			sendLog(port, fmt.Sprintf(`{"error": "%s"}`, err.Error()))
		}
		fresp, err := json.Marshal(jsonResp)
		if err != nil {
			sendLog(port, fmt.Sprintf(`{"error": "%s"}`, err.Error()))
		}
		sendLog(port, string(fresp))
		sendLog(port, "done")

	}(query)
}

//export NativeSearchAnime
func NativeSearchAnime(port C.Dart_Port, query *C.char, limit C.int) {
	quer := C.GoString(query)
	li := int(limit)

	if guestClient == nil {
		// Auto-initialize if Flutter didn't call InitGuestClient yet
		InitGuestClient()
	}
	go func(q string, l int) {

		jsonResponse, err := guestClient.SearchAnime(q, l)

		if err != nil {
			sendLog(port, fmt.Sprintf(`{"error": "%s"}`, err.Error()))
		}
		fresp, err := json.Marshal(jsonResponse)

		if err != nil {
			sendLog(port, fmt.Sprintf(`{"error": "%s"}`, err.Error()))
		}

		sendLog(port, string(fresp))
		sendLog(port, "done")
	}(quer, li)

}

//export NativeAnimeDetail
func NativeAnimeDetail(port C.Dart_Port, animeID C.int) {
	id := int(animeID)

	if guestClient == nil {
		// Auto-initialize if Flutter didn't call InitGuestClient yet
		InitGuestClient()
	}

	// Spin a goroutine so Flutter remains totally non-blocking on the main UI thread
	go func(targetID int) {
		detailResponse, err := guestClient.GetAnimeDetail(targetID)
		if err != nil {
			sendLog(port, fmt.Sprintf(`{"error": "%s"}`, err.Error()))
			sendLog(port, "done")
			return
		}

		fresp, err := json.Marshal(detailResponse)
		if err != nil {
			sendLog(port, fmt.Sprintf(`{"error": "%s"}`, err.Error()))
			sendLog(port, "done")
			return
		}

		sendLog(port, string(fresp))
		sendLog(port, "done")
	}(id)
}
func sendLog(port C.Dart_Port, message string) {
	if dartPostCObject == nil {
		return
	}
	var cobj C.Dart_CObject
	cobj._type = C.Dart_CObject_kString
	cStr := C.CString(message)
	*(*[8]byte)(unsafe.Pointer(&cobj.value)) = *(*[8]byte)(unsafe.Pointer(&cStr))
	C.CallDartPostCObject(dartPostCObject, port, &cobj)
	C.free(unsafe.Pointer(cStr))
}

func main() {}

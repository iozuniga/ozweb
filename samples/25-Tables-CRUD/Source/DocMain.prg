/*
This sample shows how to easily update any Table data.

IMPORTANT NOTE:
It does not work correctly on Xailer IDE CGI runner, since it does not
support Fetch operations a this moment.

To retrieve the data we use the method WTable:LoadFromService()

oBtn:OnClick := oTable:LoadFromService( cService )

Where cService is a method on current WDocMain objet.

This method should return a multi-dimension array in Json Format:

   a := { ;
         {"row1.data1", "row1.data2", ..., "row1.dataN" },;
         ... ,;
         {"rowN.data1", "rowN.data2", ..., "rowN.dataN" },;
        }

   RETURN hb_JsonEncode( a )
*/

#include "XailerWeb.ch"

CLASS WDocMain FROM WDoc

   DATA oMainPage
   DATA oFormPage
   DATA oForm
   DATA oTable

   METHOD CreateDoc()

   METHOD DefaultPage()
   METHOD FormPage()

   METHOD Srv_TableData( hParam )
   METHOD Srv_TableEdit( hParam )
   METHOD Srv_TableDelete( hParam )
   METHOD Srv_CheckUserCode( hParam )

END CLASS

//------------------------------------------------------------------------------

METHOD CreateDoc() CLASS WDocMain

   #ifdef _LINUX_
      Engine:cLogFile := "/mnt/c/xailerweb/samples/24-Tables-LoadData/error.log"
   #endif

   Engine:lDebug := .t.

   WITH OBJECT WBasicContext():New( Self )
      :cTheme := "light"
   END WITH

   ::DefaultPage()
   ::FormPage()

RETURN nil

//------------------------------------------------------------------------------

METHOD DefaultPage() CLASS WDocMain

   LOCAL oBtn1, oBtn2, oBtn3, oBtn4, oPackage, oModal
   LOCAL aHeader
   LOCAL cCode, cJs

   ::oMainPage := ::AddPage( "Default" )

   TEXT INTO cJs
   function jsrowClick(event) {
      const ele = document.getElementById( "rowInfo" );
      if (ele) {
         ele.innerHTML = "<p>Recno: " + event.detail.recno + " (resolved in Javascript)</p>"
      }
   }

   ta = document.getElementById("source");
   if (ta) {
      ta.value = xw_b64toUnicode(ta.value);
   }
   delete ta;
   ENDTEXT

   ::AddScript( cJs )

   aHeader := { {"Id","First","Last","Street","City"} }

   ECHO "<h2>XailerWeb: Table CRUD</h2>" INTO ::oMainPage

   ECHO "This example does not perform any additional web page loading. All its operations are contained in this single initial charge" INTO ::oMainPage

   WITH OBJECT WText():New ( ::oMainPage )
      :cId := "rowInfo"
      :cText := "<p>Click on any row</p>"
      :Create()
   END WITH

   WITH OBJECT oBtn1 := WCmpButtonSpinner():New( ::oMainPage )
      :cText := "Load 477 records from a Json file on server via Fetch API with XailerWeb built-in system"
      :cId := "button1"
   END WITH

   WITH OBJECT WDiv():New( ::oMainPage )
      WITH OBJECT oBtn2 := WButton():New( SO )
         :cText := "Append"
         :cId := "btnAppend"
      END WITH
      WITH OBJECT oBtn3 := WButton():New( SO )
         :cText := "Edit"
         :cId := "btnEdit"
      END WITH
      WITH OBJECT oBtn4 := WButton():New( SO )
         :cText := "Delete"
         :cId := "btnDelete"
      END WITH
   END WITH

   WITH OBJECT ::oTable := WTable():New( ::oMainPage )
      :cId := "table1"
      :oStyle:cWidth := "100%"
      :LoadData( aHeader, .t. ) // Second parameter .T., indicates that first column field is an ID (Pk)
      :nHeader := 1
      :lResponsive := .T.
      :lCanSort := .t.
      :lShowId := .t.
      :lCanFilter := .t.
      :lShowSelected := .t.
      :OnRowClick := "jsrowClick"
      :cBtnEditID := oBtn3:cId
      :cBtnDelID  := oBtn4:cId
      :Create()
   END WITH

   oPackage := WModalMsgBtn():New( Self )
   oModal   := oPackage:ShowModal("XailerWeb: Table CRUD", "Confirm row deletion?", {"OK", "Cancel"} )

   WITH OBJECT oModal
      :OnClick( 1, ::oTable:DeleteFromService( "Srv_TableDelete", oBtn4:cId ) )
   END WITH

   oBtn1:OnClick := ::oTable:LoadFromService( "Srv_TableData", oBtn1:cId )
   oBtn2:OnClick := ::oTable:Append( "Page_FormPage" )
   oBtn3:OnClick := ::oTable:Edit( "Page_FormPage" )
   oBtn4:OnClick := oModal

   FILE "DocMain.prg" INTO cCode

   ECHO "<hr>" INTO ::oMainPage

   WITH OBJECT WTextArea():New( ::oMainPage )
      :nCols := 100
      :cId   := "source"
      :nRows := 40
      :cText := HB_Base64Encode( cCode )
      :lReadOnly := .t.
      :Create()
   END WITH

RETURN nil

//------------------------------------------------------------------------------

METHOD FormPage() CLASS WDocMain

   LOCAL oGroup

   WITH OBJECT ::oFormPage := ::AddPage( "Page_FormPage" )
     :lHide   := .T.
     :lForced := .T.
     :lFooter := .T.
   END WITH

   WITH OBJECT ::oForm := WForm():New( ::oFormPage )
      :cMethod := "post"
      :cName := "myform"
      :cTableId := "table1"
      :lAutoComplete := .T.
      :lModal := .t.
      :AddStyle( "width: 80ch;" )
      :OnSubmit := :SubmitToService( "Srv_TableEdit", .T. )
      :Create()
      WITH OBJECT oGroup := WFieldset():New( ::oForm )
         :cLegend := "Personal data"
         :cName := "User data"
         :Create()
         WITH OBJECT WNumber():New( oGroup )
            :cId := "Id"
            :cPlaceHolder := "id"
            :cText := " (5 digits)"
            :cLabel := "Id:"
            :cDataField := "Id"
            :lDisabledOnEdit := .T.
            :nMin := 1
            :nMax := 99999
            :nSize := 5
            :OnValidate := "Srv_CheckUserCode"
            :lLabelNewLine := .t.
            :Create()
         END WITH
         WITH OBJECT WEdit():New( oGroup )
            :cId := "first"
            :cLabel := "First:"
            :cPlaceHolder := "first"
            :cDataField := "First"
            :nMaxLength := 50
            :nMinLength := 4
            :lLabelNewLine := .T.
            :Create()
         END WITH
         WITH OBJECT WEdit():New( oGroup )
            :cId := "last"
            :cLabel := "Last:"
            :cPlaceHolder := "last"
            :cDataField := "Last"
            :nMaxLength := 50
            :nMinLength := 4
            :lLabelNewLine := .T.
            :Create()
         END WITH
         WITH OBJECT WEdit():New( oGroup )
            :cId := "street"
            :cPlaceHolder := "street"
            :cLabel := "Street:"
            :cDataField := "Street"
            :nMaxLength := 50
            :nMinLength := 10
            :lLabelNewLine := .T.
            :Create()
         END WITH
         WITH OBJECT WEdit():New( oGroup )
            :cId := "city"
            :cPlaceHolder := "city"
            :cLabel := "City:"
            :cDataField := "City"
            :nMaxLength := 50
            :nMinLength := 4
            :lLabelNewLine := .T.
            :Create()
         END WITH
      END WITH
      WITH OBJECT WButton():New( ::oForm )
         :cType := "submit"
         :cText := "Ok"
         :cId := "btnOk"
         :cForm := "myform"
         :Create()
      END WITH
      WITH OBJECT WButton():New( ::oForm )
         :cText := "Cancel"
         :cId := "btnCancel"
         :cType := "cancel"
         :Create()
      END WITH
      WITH OBJECT WButton():New( ::oForm )
         :cText := "Reset"
         :cId := "btnReset"
         :cType := "reset"
         :Create()
      END WITH
   END WITH

RETURN ::oFormPage

//------------------------------------------------------------------------------
/*
Note: Table data is on CGI PATH + "/data"
*/

METHOD Srv_TableData( hParam ) CLASS WDocMain

   LOCAL hData
   LOCAL cFile, cJson

   cFile := HB_DirBase() + "data/data.json"

   IF !File( cFile )
      RETURN  '{ "Error": "File not found: ' + cFile + '"}'
   ENDIF

   cJson := HB_MemoRead( cFile )
   HB_JsonDecode( cJson, @hData )

RETURN cJson

//------------------------------------------------------------------------------

METHOD Srv_TableEdit( hParam ) CLASS WDocMain

   LOCAL hData := Engine:hPost
   LOCAL lAppend

   lAppend := ( HB_HGetDef( hParam, "append_mode", "" ) == "true" )

   // Here goes your code to check that the edit or append operation is
   // correct and update your database accordly.
   // If you change any field value, remeber to return the JSON modified

//   FOR EACH cKey, cValue IN HB_HKeys( hData ), HB_HValues( hData )
//      HB_HSet( hData, cKey, YourFunction( cValue ) )
//   NEXT

RETURN HB_JsonEncode( hData )

//------------------------------------------------------------------------------

METHOD Srv_TableDelete( hParam ) CLASS WDocMain

   LOCAL hResult := { => }

   HB_HSet( hResult, "pass", .t. )

RETURN HB_JsonEncode( hResult )

//------------------------------------------------------------------------------

METHOD Srv_CheckUserCode( hParam ) CLASS WDocMain

   LOCAL hRet, hData
   LOCAL aData, aRow
   LOCAL cId, cJson
   LOCAL nAt, nId
   LOCAL lAppend

   hRet    := { => }
   aData   := {}
   lAppend := ( HB_HGetDef( hParam, "append_mode", "" ) == "true" )

   IF lAppend
      cId := HB_HGetDef( hParam, "value", "" )
      nId := Val( cId )
      IF Empty( nId )
         HB_HSet( hRet, "pass", .F. )
         HB_HSet( hRet, "error", "ID field must have a value" )
      ELSE
         cJson := HB_MemoRead( HB_DirBase() + "data/data.json" )
         HB_JsonDecode( cJson, @hData )
         aData := {}
         FOR EACH aRow IN hData
            IF Len( aRow ) > 0
               AAdd( aData, aRow )
            ENDIF
         NEXT
         nAt := AScan( aData, {|v| Len(v) > 0 .AND. v[ 1 ] == nId } )
         IF nAt > 0
            HB_HSet( hRet, "pass", .F. )
            HB_HSet( hRet, "error", "The code " + cId + " already exists in the file (resolved in Harbour)")
         ELSE
            HB_HSet( hRet, "pass", .T. )
            HB_HSet( hRet, "error", "")
         ENDIF
      ENDIF
   ELSE
      HB_HSet( hRet, "pass", .T. )
      HB_HSet( hRet, "error", "" )
   ENDIF

RETURN HB_JsonEncode( hRet )

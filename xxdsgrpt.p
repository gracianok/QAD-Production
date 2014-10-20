/*xxdsgrpt DSG Daily Production Report */
/*Argen-WO3458 ken graciano - Initial Release*/
/*Argen-WO3530 ken graciano - include all open orders*/

{mfdtitle.i "A"}

DEF VAR fr_slspsn LIKE cm_slspsn[1].
DEF VAR to_slspsn LIKE cm_slspsn[1].
DEFINE VAR fr_date LIKE pt_mod_date.
DEFINE VAR to_date LIKE pt_mod_date.
DEF VAR fr_ancode LIKE ad_addr NO-UNDO.
DEF VAR to_ancode LIKE ad_addr NO-UNDO.
DEF VAR part LIKE pt_part NO-UNDO.
DEF VAR part1 LIKE pt_part NO-UNDO.
DEF VAR tot_qty AS DECIMAL NO-UNDO.
DEF VAR tot_cost AS DECIMAL NO-UNDO.
DEF VAR totdays AS INTEGER NO-UNDO.
DEF VAR daily AS INTEGER NO-UNDO.

DEFINE VARIABLE vroute AS CHARACTER
 VIEW-AS RADIO-SET HORIZONTAL RADIO-BUTTONS "Print" , "P" ,
  "Email", "E" INITIAL "P".
DEF STREAM emailit.

def var sendmail as character.


FORM 
SKIP(1)
fr_date LABEL "Date" COLON 22
TO_date LABEL "To" COLON 45 SKIP
vroute LABEL "Route"  colon 22  
SKIP(1)
WITH FRAME a.

{wbrp01.i}

DISPLAY "Email Route is DSG_Report." WITH FRAME a.
REPEAT:

    TO_date = TODAY.
    
    IF TO_date = hi_date THEN TO_date = TODAY.
    IF fr_date = low_date THEN fr_date = ?.

    UPDATE
    fr_date
    TO_date
    vroute
    WITH FRAME a CENTERED SIDE-LABELS.

   
    /* OUTPUT DESTINATION SELECTION */

    bcdparm = "".

    {mfquoter.i fr_date          }
    {mfquoter.i to_date          }     
    
    {mfquoter.i vroute             }

     IF TO_date = ? THEN TO_date = TODAY.
     IF fr_date = ? THEN fr_date = TODAY.
     
    /* IF batchrun THEN ASSIGN TO_date = TODAY fr_date = ?.
      */

    {mfselbpr.i "printer" 132}   
    {mfphead.i}

    tot_qty = 0.
    tot_cost = 0.

    IF vroute = "E" THEN OUTPUT STREAM emailit TO DSG_Report.csv.

    /*FOR EACH wo_mstr WHERE wo_domain = "us1" AND wo_site = "22" AND wo_due_date >= fr_date AND wo_due_date <= TO_date NO-LOCK,*/
        FOR EACH so_mstr WHERE so_domain = "us1" AND so_site = "22" /*AND so_due_date >= fr_date AND so_due_date <= TO_date**/ NO-LOCK,
        EACH sod_det WHERE sod_domain = "us1" AND sod_site = "22" AND sod_nbr = so_nbr NO-LOCK,
        EACH pt_mstr WHERE pt_domain = "us1" AND pt_part = sod_part NO-LOCK,
        EACH cm_mstr WHERE cm_domain = "Us1" AND cm_addr = so_cust NO-LOCK BREAK BY so_cust.
   
        IF FIRST(so_cust) THEN EXPORT STREAM emailit DELIMITER "," "Order Date" "Due DAte" "Order-No" "Customer Name" "Case" "Description" "Orig STL" "Revised STL". 

        FIND FIRST cmt_det WHERE cmt_domain = "us1" AND cmt_indx = sod_cmtindx NO-LOCK NO-ERROR.
        

        IF so_cust = "Z151" THEN DO:

            FIND FIRST xxdigrel_mstr WHERE xxdigrel_domain = "us1" AND xxdigrel_so = so_nbr NO-LOCK NO-ERROR.
            

            IF vroute = "E" AND xxdigrel_cust_name MATCHES "DSG*" THEN EXPORT STREAM emailit DELIMITER "," so_ord_date so_due_date so_nbr xxdigrel_cust_name WHEN AVAILABLE xxdigrel_mstr cmt_cmmt[01] pt_desc1 sod__chr08
                replace(replace(replace(replace(replace(sod__chr08,"#","_"),",","_"),"+","_"),"#","_"),"%","_").
            
            IF xxdigrel_cust_name MATCHES "DSG*" THEN DISPLAY so_ord_date so_due_date so_nbr xxdigrel_cust_name WHEN AVAILABLE xxdigrel_mstr cmt_cmmt[01]  pt_desc1 sod__chr08.
        END.

        

        IF vroute = "E" AND cm_sort MATCHES "DSG*" THEN EXPORT STREAM emailit DELIMITER "," so_ord_date so_due_date so_nbr cm_sort cmt_cmmt[01] pt_desc1 sod__chr08 
            replace(replace(replace(replace(replace(sod__chr08,"#","_"),",","_"),"+","_"),"#","_"),"%","_").

        IF cm_sort MATCHES "DSG*" THEN DISPLAY so_ord_date so_due_date so_nbr cm_sort cmt_cmmt[01] pt_desc1 sod__chr08.

    END.



    IF vroute = "E" THEN OUTPUT STREAM emailit CLOSE. 
    IF vroute = "E" THEN DO:    
        FOR EACH qad_wkfl WHERE qad_domain = GLOBAL_domain 
        AND qad_key2 = "DSG_Report" AND qad_logfld[01] NO-LOCK.            
            sendmail = "mutt -a DSG_Report.csv -s 'DSG Daily Report' " + qad_charfld[01] + "< /dev/null".
            os-command silent value(sendmail).             
        END.
    END.
    {mfreset.i}

END.

{wbrp04.i &frame-spec = a}

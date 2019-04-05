/* fetch, control and data address checks for extensions */

union Ext_Fetch_Check ('a : Type) = {
  Ext_Fetch_OK  : xlenbits,  /* PC value to use for the actual fetch */
  Ext_Fetch_Error : 'a
}

union Ext_Control_Check ('a : Type) = {
  Ext_Control_OK : xlenbits, /* PC value to use for the target of the control operation */
  Ext_Control_Error : 'a
}

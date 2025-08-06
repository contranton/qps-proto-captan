-------------------------------------------------------------------------------
--
--        _-    -_
--       |  |  |  |            Fermi National Accelerator Laboratory
--       |  |  |  |
--       |  |  |  |        Operated by Fermi Forward Discovery Group, LLC
--       |  |  |  |        for the Department of Energy under contract
--       /  |  |   \                    89243024CSC000002
--      /   /   \   \
--     /   /     \   \
--     ----       ----
-------------------------------------------------------------------------------
-- Title      : Buffer-based queue for async writing
-- Project    :
-------------------------------------------------------------------------------
-- File       : pkg_BufferQueue.vhd
-- Author     : Javier Contreras 52425N
-- Division   : CSAID/RTPS/DIS
-- Created    : 2025-08-06
-- Last update: 2025-08-06
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2025 Fermi Forward Discovery Group, LLC
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2025-08-06  1.0      javierc	Created
-------------------------------------------------------------------------------
package pkg_BufferQueue is

  generic (
    type t_TYPE;
    type t_POINTER
    );

  type t_arr_TYPE is array(natural range <>) of t_TYPE;

  procedure proc_BufferPush(
    signal arg_Buffer  : inout t_arr_TYPE;
    signal arg_Pointer : inout t_POINTER;
    constant arg_Data  : in    t_TYPE
    );

  procedure proc_BufferPop(
    signal arg_Buffer  : inout t_arr_TYPE;
    signal arg_Pointer : inout t_POINTER;
    signal res_Data  : out    t_TYPE
    );

  procedure proc_BufferReset(
    signal arg_Buffer  : inout t_arr_TYPE;
    signal arg_Pointer : out   t_POINTER
    );

end package pkg_BufferQueue;

--  ____            _
-- | __ )  ___   __| |_   _
-- |  _ \ / _ \ / _` | | | |
-- | |_) | (_) | (_| | |_| |
-- |____/ \___/ \__,_|\__, |
--                    |___/

package body pkg_BufferQueue is

  procedure proc_BufferPush(
    signal arg_Buffer  : inout t_arr_TYPE;
    signal arg_Pointer : inout t_POINTER;
    constant arg_Data  : in    t_TYPE
    ) is
  begin
    arg_Pointer             <= arg_Pointer + 1;
    arg_Buffer(arg_Pointer) <= arg_Data;
  end procedure proc_BufferPush;

  procedure proc_BufferReset(
    signal arg_Buffer  : inout t_arr_TYPE;
    signal arg_Pointer : out   t_POINTER
    ) is
  begin
    for idx in 0 to arg_Buffer'length - 1 loop
      arg_Buffer(idx) <= (address => x"00", data => x"0000");
    end loop;
    arg_Pointer <= 0;
  end procedure proc_BufferReset;

  procedure proc_BufferPop(
    signal arg_Buffer  : inout t_arr_TYPE;
    signal arg_Pointer : inout t_POINTER;
    signal res_Data  : out    t_TYPE
    ) is
  begin
    arg_Pointer             <= arg_Pointer - 1;
    res_Data <= arg_Buffer(arg_Pointer);
  end procedure proc_BufferPop;


end package body pkg_BufferQueue;

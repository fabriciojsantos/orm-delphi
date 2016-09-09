object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 405
  ClientWidth = 985
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    985
    405)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 416
    Top = 15
    Width = 66
    Height = 13
    Caption = 'Log File (SQL)'
  end
  object Button1: TButton
    Left = 8
    Top = 16
    Width = 384
    Height = 57
    Caption = 'Connect Data Base'
    TabOrder = 0
    OnClick = Button1Click
  end
  object btnSave: TButton
    Left = 8
    Top = 83
    Width = 121
    Height = 57
    Caption = 'Save Object'
    TabOrder = 1
    OnClick = btnSaveClick
  end
  object btnUpdate: TButton
    Left = 140
    Top = 83
    Width = 121
    Height = 57
    Caption = 'Update Object'
    TabOrder = 2
    OnClick = btnUpdateClick
  end
  object btnFind: TButton
    Left = 271
    Top = 83
    Width = 121
    Height = 57
    Caption = 'Find Object'
    TabOrder = 3
    OnClick = btnFindClick
  end
  object Memo1: TMemo
    Left = 8
    Top = 214
    Width = 384
    Height = 165
    Anchors = [akLeft, akTop, akBottom]
    TabOrder = 4
  end
  object Memo2: TMemo
    Left = 416
    Top = 34
    Width = 553
    Height = 345
    Anchors = [akLeft, akTop, akRight, akBottom]
    TabOrder = 5
  end
  object btnSpExec: TButton
    Left = 8
    Top = 146
    Width = 253
    Height = 57
    Caption = 'Execute Stored Procedure Object'
    TabOrder = 6
    OnClick = btnSpExecClick
  end
end

declare void @init_reader()
declare void @init_eval()

define void @init() {
       call void @init_reader()
       call void @init_eval()
       ret void
}
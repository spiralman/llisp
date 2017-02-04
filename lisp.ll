declare void @init_reader()

define void @init() {
       call void @init_reader()
       ret void
}
import controllerremap.ControllerState;
class ControllerStateTest {
    static var checks=0;
    static function check(ok:Bool,label:String):Void {checks++;if(!ok)throw label;}
    static function buttons(indices:Array<Int>):Array<Bool> return [for(i in 0...24)indices.indexOf(i)>=0];
    static function main():Void {
        var p=new ControllerState(),none=buttons([]),a=buttons([0]),b=buttons([1]),chord=buttons([8,9]);
        p.update(a,true,true,true,1);check(!p.navigation,"opening press cannot activate a widget");
        p.update(none,true,true,true,1.1);p.update(a,true,true,true,1.2);check(p.navigation,"fresh UI input can navigate");
        p.begin(2,2);check(p.listening&&!p.navigation,"Listen immediately suspends UI navigation");
        check(p.update(a,true,true,true,2.1)==-1&&p.listening,"opening A cannot bind itself");
        p.update(none,true,true,true,2.2);
        check(p.update(b,true,true,true,2.3)==1&&!p.listening&&p.slot==2,"B is a bindable button rather than capture cancellation");
        p.update(b,true,true,true,2.4);check(!p.navigation,"captured B cannot dismiss the next dialog");
        p.update(none,true,true,true,2.5);p.update(a,true,true,true,2.6);check(p.navigation,"navigation resumes only after release");
        for(i in 0...24){
            p.begin(0,3);p.update(none,true,true,true,3.1);
            check(p.update(buttons([i]),true,true,true,3.2)==i,"every exposed button/stick direction is assignable: "+i);
        }
        p.begin(1,4);p.update(none,true,true,true,4.1);
        check(p.update(buttons([0,1]),true,true,true,4.2)==-1&&p.listening,"ambiguous simultaneous buttons require another press");
        check(p.update(a,true,true,true,4.3)==-1,"ambiguous press must fully release");
        p.update(none,true,true,true,4.4);check(p.update(a,true,true,true,4.5)==0,"capture recovers after ambiguity");
        p.begin(0,5);p.update(none,true,true,true,5.1);p.update(a,false,true,true,5.2);
        check(!p.listening&&!p.navigation,"disconnect cancels without binding");
        p.begin(0,6);p.update(a,true,false,true,6.1);check(!p.listening,"Alt-Tab cancels listening");
        p.begin(0,7);p.update(a,true,true,false,7.1);check(!p.listening,"closing editor cancels listening");
        p.begin(0,8);p.update(none,true,true,true,8.1);p.update(a,true,true,true,20);
        check(!p.listening&&p.message.indexOf("timed out")>=0,"late press cannot bind after timeout");
        p=new ControllerState();p.update(chord,true,true,false,21);check(!p.toggle,"held reconnect chord does not open");
        p.update(none,true,true,false,21.1);p.update(chord,true,true,false,21.2);check(p.toggle,"fresh Back+Start toggles editor");
        p.update(chord,true,true,true,21.3);check(!p.toggle,"held chord toggles once");
        p.begin(0,22);p.update(none,true,true,true,22.1);p.update(chord,true,true,true,22.2);
        check(!p.toggle&&p.listening,"capture owns even the window toggle buttons");
        p.cancel();check(!p.listening&&p.slot<0&&!p.navigation,"cancel drops capture and navigation");
        p.update(none,true,true,true,23);p.update(buttons([5]),true,true,true,23.1);
        check(p.paneDirection==1,"RB requests the next section");
        p.update(buttons([5]),true,true,true,23.2);check(p.paneDirection==0,"held RB does not cycle repeatedly");
        p.update(none,true,true,true,23.3);p.update(buttons([4]),true,true,true,23.4);
        check(p.paneDirection==-1,"LB requests the previous section");
        p.update(none,true,true,true,23.5);p.update(buttons([4,5]),true,true,true,23.6);
        check(p.paneDirection==0,"opposing shoulders do not change section");
        p.begin(0,24);p.update(none,true,true,true,24.1);
        check(p.update(buttons([5]),true,true,true,24.2)==5&&p.paneDirection==0,"Listen captures RB without switching section");
        var modifiers=buttons([5,6,7]),shortcut=buttons([0,5,6,7]);
        p=new ControllerState();p.update(none,true,true,false,30);
        p.update(modifiers,true,true,false,30.1);check(!p.toggle,"LT+RT+RB alone does not open");
        p.update(shortcut,true,true,false,30.2);check(p.toggle&&!p.navigation,"hold LT+RT+RB then press A opens without activating a widget");
        p.update(shortcut,true,true,true,30.3);check(!p.toggle&&!p.navigation&&p.paneDirection==0,"held opening combo cannot repeat, navigate or switch sections");
        p.update(buttons([0,5,7]),true,true,true,30.4);check(!p.toggle&&!p.navigation,"partial release cannot leak the held A into the editor");
        p.update(a,true,true,true,30.5);check(!p.navigation,"A stays consumed until all opening buttons release");
        p.update(none,true,true,true,30.6);p.update(a,true,true,true,30.7);check(p.navigation&&!p.toggle,"fresh A navigates normally after opening combo release");
        p.update(none,true,true,true,31);p.update(modifiers,true,true,true,31.1);
        check(!p.toggle&&!p.navigation&&p.paneDirection==0,"holding shortcut modifiers reserves RB instead of switching sections");
        p.update(shortcut,true,true,true,31.2);check(p.toggle&&!p.navigation,"same combo closes an open panel");
        for(missing in [0,5,6,7]){
            p=new ControllerState();p.update(none,true,true,false,32);
            p.update(buttons([for(i in [0,5,6,7])if(i!=missing)i]),true,true,false,32.1);
            check(!p.toggle,"missing any required combo button cannot toggle: "+missing);
        }
        p=new ControllerState();p.update(none,true,true,false,33);p.update(a,true,true,false,33.1);p.update(shortcut,true,true,false,33.2);
        check(!p.toggle,"A must be a fresh press after holding shortcut modifiers");
        p.update(modifiers,true,true,false,33.3);p.update(shortcut,true,true,false,33.4);check(p.toggle,"release and press A again while modifiers stay held works");
        p=new ControllerState();p.update(shortcut,true,true,false,34);check(!p.toggle,"held startup combo does not open");
        p.update(shortcut,false,true,false,34.1);p.update(shortcut,true,true,false,34.2);check(!p.toggle,"held reconnect combo does not open");
        p.update(modifiers,true,true,false,34.3);p.update(shortcut,true,true,false,34.4);check(p.toggle,"fresh A after reconnect works");
        p.update(modifiers,true,false,true,34.5);p.update(shortcut,true,true,true,34.6);check(!p.toggle&&!p.navigation,"held focus-return combo cannot toggle or activate");
        p.begin(0,35);p.update(none,true,true,true,35.1);p.update(shortcut,true,true,true,35.2);
        check(!p.toggle&&p.listening,"Listen owns the combo and keeps the panel open");
        p=new ControllerState();p.update(none,true,true,true,40);p.update(buttons([2]),true,true,true,40.1);
        check(p.regionDirection==1,"fresh X moves to next panel region");
        p.update(buttons([2]),true,true,true,40.2);check(p.regionDirection==0,"held X cannot race through regions");
        p.update(none,true,true,true,40.3);p.update(buttons([3]),true,true,true,40.4);check(p.regionDirection==-1,"Y moves to previous panel region");
        p.update(none,true,true,true,40.5);p.update(buttons([2,3]),true,true,true,40.6);check(p.regionDirection==0,"opposing region shortcuts do not jump focus");
        p.begin(0,41);p.update(none,true,true,true,41.1);check(p.update(buttons([2]),true,true,true,41.2)==2&&p.regionDirection==0,"Listen captures X without navigating away");
        p=new ControllerState();p.update(none,true,true,true,42);p.update(buttons([21]),true,true,true,42+1./60);
        check(Math.abs(p.scrollY-7)<0.001&&p.used,"fresh right stick scrolls at time-based speed and reclaims controller mode");
        p.update(buttons([21]),true,true,true,42+2./60);check(Math.abs(p.scrollY-7)<0.001&&!p.used,"held right stick continues scrolling without fresh selection");
        p.update(buttons([20,21]),true,true,true,42+3./60);check(p.scrollY==0,"opposite stick directions cancel scrolling");
        p.update(buttons([20]),true,true,true,42+4./60);check(p.scrollY<0,"right stick up scrolls upward");
        p.update(buttons([21]),true,true,true,44);check(p.scrollY==21,"slow frames clamp scroll distance");
        p.update(buttons([21]),true,false,true,44.01);check(p.scrollY==0,"focus loss stops scrolling immediately");
        p.update(buttons([21]),true,true,true,44.02);check(p.scrollY==0,"held focus-return stick cannot scroll without neutral release");
        p.update(none,true,true,true,44.03);p.update(buttons([21]),true,true,true,44.04);p.begin(0,44.05);
        check(p.scrollY==0,"starting Listen clears scroll motion");
        p.update(none,true,true,true,44.06);check(p.update(buttons([20]),true,true,true,44.07)==20&&p.scrollY==0,"Listen captures right stick as a binding without scrolling");
        Sys.println("PASS "+checks+" controller capture and navigation lifecycle checks");
    }
}

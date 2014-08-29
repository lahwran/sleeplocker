import android.app { Activity }
import android.os { Bundle }

shared class MainActivity() extends Activity() {
    shared actual void onCreate(Bundle? savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
    }
}

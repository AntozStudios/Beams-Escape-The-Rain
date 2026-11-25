package com.antoz.beams;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import java.util.concurrent.atomic.AtomicReference;

public final class LoginCallback extends Activity {
    static final AtomicReference<String> result = new AtomicReference<>("");
    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);
        String uri = getIntent().getDataString();
        if (uri != null) result.set(uri);
        Intent game = getPackageManager().getLaunchIntentForPackage(getPackageName());
        if (game != null) {
            game.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            startActivity(game);
        }
        finish();
    }
}

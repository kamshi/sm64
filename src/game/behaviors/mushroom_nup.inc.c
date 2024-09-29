 
void bhv_nup_interact(void)
{
    if (obj_check_if_collided_with_object(o, gMarioObject) == TRUE) {
        play_sound(SOUND_GENERAL_COLLECT_1UP, gGlobalSoundSource);
        gMarioState->numLives += o->oBhvParams2ndByte;
        o->activeFlags = ACTIVE_FLAG_DEACTIVATED;
    }
}

void bhv_nup_loop(void)
{
    bhv_nup_interact();
}

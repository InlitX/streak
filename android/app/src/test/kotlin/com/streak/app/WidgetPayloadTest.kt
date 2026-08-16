package com.streak.app

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class WidgetPayloadTest {

    private fun payload(): JSONObject {
        val days = JSONArray()
        for (i in 0 until 14) {
            days.put(
                JSONObject()
                    .put("key", key(i))
                    .put("label", "d$i")
                    .put("isToday", i == 6),
            )
        }
        val completions = JSONArray()
        val counts = JSONArray()
        val scheduled = JSONArray()
        for (i in 0 until 14) {
            completions.put(i == 6)
            counts.put(if (i == 6) 1.0 else 0.0)
            scheduled.put(true)
        }
        val habit = JSONObject()
            .put("id", "a")
            .put("completions", completions)
            .put("counts", counts)
            .put("scheduled", scheduled)
        return JSONObject()
            .put("days", days)
            .put("habits", JSONArray().put(habit))
            .put("todayKey", key(6))
            .put("summary", JSONObject().put("doneToday", 1).put("total", 1))
    }

    private fun key(index: Int) = String.format("%02d-08-2026", index + 10)

    @Test
    fun `keeps the week ending today`() {
        val out = WidgetPayload.align(payload(), key(6))
        val days = out.getJSONArray("days")

        assertEquals(7, days.length())
        assertEquals(key(0), days.getJSONObject(0).getString("key"))
        assertEquals(key(6), days.getJSONObject(6).getString("key"))
        assertTrue(days.getJSONObject(6).getBoolean("isToday"))
    }

    @Test
    fun `moves the window when the day changes`() {
        val out = WidgetPayload.align(payload(), key(8))
        val days = out.getJSONArray("days")
        val habit = out.getJSONArray("habits").getJSONObject(0)

        assertEquals(key(8), days.getJSONObject(6).getString("key"))
        assertTrue(days.getJSONObject(6).getBoolean("isToday"))
        assertEquals(false, days.getJSONObject(0).getBoolean("isToday"))
        assertEquals(false, habit.getJSONArray("completions").getBoolean(6))
        assertEquals(true, habit.getJSONArray("completions").getBoolean(4))
        assertEquals(0, out.getJSONObject("summary").getInt("doneToday"))
        assertEquals(1, out.getJSONObject("summary").getInt("total"))
    }

    @Test
    fun `falls back to the newest week it knows`() {
        val out = WidgetPayload.align(payload(), "01-01-2030")
        val days = out.getJSONArray("days")

        assertEquals(7, days.length())
        assertEquals(key(13), days.getJSONObject(6).getString("key"))
        assertEquals(false, days.getJSONObject(6).getBoolean("isToday"))
        assertEquals(1, out.getJSONObject("summary").getInt("total"))
    }

    @Test
    fun `falls back to the oldest week when the clock goes back`() {
        val out = WidgetPayload.align(payload(), key(2))
        val days = out.getJSONArray("days")

        assertEquals(7, days.length())
        assertEquals(key(0), days.getJSONObject(0).getString("key"))
        assertTrue(days.getJSONObject(2).getBoolean("isToday"))
    }

    @Test
    fun `leaves an old payload untouched`() {
        val root = payload()
        val days = JSONArray()
        for (i in 0 until 7) days.put(root.getJSONArray("days").getJSONObject(i))
        root.put("days", days)

        val out = WidgetPayload.align(root, key(6))

        assertEquals(7, out.getJSONArray("days").length())
        assertEquals(14, out.getJSONArray("habits").getJSONObject(0).getJSONArray("completions").length())
    }

    @Test
    fun `counts only the habits due that day`() {
        val root = payload()
        val habit = root.getJSONArray("habits").getJSONObject(0)
        habit.getJSONArray("scheduled").put(8, false)

        val out = WidgetPayload.align(root, key(8))

        assertEquals(0, out.getJSONObject("summary").getInt("total"))
    }

    @Test
    fun `finds the window index of a day`() {
        assertEquals(9, WidgetPayload.windowIndexOf(payload(), key(9)))
        assertEquals(-1, WidgetPayload.windowIndexOf(payload(), "01-01-2030"))
    }
}

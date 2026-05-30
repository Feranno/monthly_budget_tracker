#!/bin/bash
sed -i "s|__SUPABASE_URL__|$SUPABASE_URL|g" index.html auth.html
sed -i "s|__SUPABASE_ANON__|$SUPABASE_ANON|g" index.html auth.html
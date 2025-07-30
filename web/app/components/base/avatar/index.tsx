'use client'
import cn from '@/utils/classnames'

export type AvatarProps = {
  name: string
  avatar: string | null
  size?: number
  className?: string
  textClassName?: string
}
const Avatar = ({
  name,
  avatar,
  size = 30,
  className,
  textClassName,
}: AvatarProps) => {
  const avatarClassName = 'shrink-0 flex items-center rounded-full bg-primary-600'
  const style = { width: `${size}px`, height: `${size}px`, fontSize: `${size}px`, lineHeight: `${size}px` }

  // Always use the fixed profile image
  return (
    <img
      className={cn(avatarClassName, className)}
      style={style}
      alt={name}
      src="/logo/profile.png"
    />
  )
}

export default Avatar
